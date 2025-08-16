"""
Build the Gold layer (aggregates) from the cleaned Silver layer (Parquet).

What it does:
1) Discovers the latest `ingestion_date` in Silver if not provided.
2) Reads Silver Parquet: s3a://{SILVER_BUCKET}/{DATASET_NAME}/ingestion_date=YYYY-MM-DD
3) Aggregates counts by (country, state, brewery_type)
4) Writes **Delta Lake** to Gold:
   s3a://{GOLD_BUCKET}/{GOLD_DATASET_NAME}/ingestion_date=YYYY-MM-DD
   partitioned by (country, state)

Env vars (overridable via Glue Job args):
- DATASET_NAME       default: "openbrewerydb"   (silver dataset prefix)
- GOLD_DATASET_NAME  default: "openbrewerydb_agg"
- SILVER_BUCKET      default: "bees-lakehouse-silver-dev"
- GOLD_BUCKET        default: "bees-lakehouse-gold-dev"

Args:
--ingestion_date YYYY-MM-DD   (optional; auto-discovered if omitted)
--dataset_name <name>
--gold_dataset_name <name>
--silver_bucket <bucket>
--gold_bucket <bucket>
--discover_only true|false    (optional: only discover date and exit)
"""

import os
import re
import boto3
from pyspark.sql import SparkSession, functions as F


def discover_latest_ingestion_date(bucket: str, dataset: str) -> str:
    """
    Discover the max ingestion_date from:
    s3://{bucket}/{dataset}/ingestion_date=YYYY-MM-DD/
    """
    s3 = boto3.client("s3")
    prefix = f"{dataset}/ingestion_date="
    resp = s3.list_objects_v2(Bucket=bucket, Prefix=prefix, Delimiter="/", MaxKeys=1000)
    prefixes = [cp["Prefix"] for cp in resp.get("CommonPrefixes", [])]
    if not prefixes:
        raise RuntimeError(f"No ingestion_date found under s3://{bucket}/{dataset}/")

    dates = []
    for p in prefixes:
        m = re.search(r"ingestion_date=(\d{4}-\d{2}-\d{2})/", p)
        if m:
            dates.append(m.group(1))
    if not dates:
        raise RuntimeError(f"Ingestion_date prefixes exist but none matched the expected pattern: {prefixes}")

    return max(dates)


# ---------------------------
# Spark bootstrap (Delta)
# ---------------------------
def get_spark(app_name: str = "gold_breweries"):
    return (
        SparkSession.builder.appName(app_name)
        .config("spark.sql.session.timeZone", "UTC")
        .config("spark.sql.sources.partitionOverwriteMode", "dynamic")
        # Delta Lake configs
        .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension")
        .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog")
        # Log store recomendado para S3
        .config("spark.delta.logStore.class", "org.apache.spark.sql.delta.storage.S3SingleDriverLogStore")
        .getOrCreate()
    )


# ---------------------------
# I/O and transform
# ---------------------------
def read_silver(spark: SparkSession, bucket: str, dataset: str, ingestion_date: str):
    path = f"s3a://{bucket}/{dataset}/ingestion_date={ingestion_date}"
    return spark.read.parquet(path)

def aggregate(df):
    return (
        df.groupBy("country", "state", "brewery_type")
        .agg(F.count(F.lit(1)).alias("breweries_count"))
    )

def write_gold(df, bucket: str, dataset: str, ingestion_date: str):
    out = f"s3a://{bucket}/{dataset}/ingestion_date={ingestion_date}"
    (
        df.write
        .format("delta")
        .mode("overwrite")                 # substitui a partição do dia
        .partitionBy("country", "state")
        .save(out)
    )


# ---------------------------
# Entrypoint
# ---------------------------
def main():
    # Somente via ENV (ou defaults do código). Nada de CLI.
    dataset_name      = os.getenv("DATASET_NAME",      "openbrewerydb")
    gold_dataset_name = os.getenv("GOLD_DATASET_NAME", "openbrewerydb_agg")
    silver_bucket     = os.getenv("SILVER_BUCKET",     "bees-lakehouse-silver-dev")
    gold_bucket       = os.getenv("GOLD_BUCKET",       "bees-lakehouse-gold-dev")

    spark = get_spark()
    try:
        ingestion_date = discover_latest_ingestion_date(silver_bucket, dataset_name)
        print(f"[auto] discovered ingestion_date={ingestion_date}")

        silver_df = read_silver(spark, silver_bucket, dataset_name, ingestion_date)
        agg_df = aggregate(silver_df)
        write_gold(agg_df, gold_bucket, gold_dataset_name, ingestion_date)
        print(f"OK gold (delta) {ingestion_date} rows={agg_df.count()}")
    finally:
        spark.stop()

if __name__ == "__main__":
    main()