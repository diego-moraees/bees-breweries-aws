"""
Transform breweries JSON landed in the Bronze layer into a cleaned,
columnar Silver layer (Parquet) partitioned by country and state.

This script:
1) Reads the Bronze JSON for an `ingestion_date` (auto-discovered if not provided).
2) Normalizes types and trims strings; handles missing state/country.
3) Deduplicates by the brewery `id` keeping the latest record.
4) Writes Parquet to the Silver bucket partitioned by `country` and `state`:
   s3a://<SILVER_BUCKET>/<DATASET_NAME>/ingestion_date=YYYY-MM-DD/...

Environment variables (overridable via Glue Job arguments, see notes):
- DATASET_NAME       (default: "openbrewerydb")
- BRONZE_BUCKET      (default: "bees-lakehouse-bronze-dev")
- SILVER_BUCKET      (default: "bees-lakehouse-silver-dev")

Notes:
- Input JSON files are arrays; we use `multiLine=true` to parse them.
- Bronze layout (from your Lambda): <dataset>/run_date=YYYY-MM-DD/page=*/breweries.json
- We accept --ingestion_date YYYY-MM-DD (optional).
- You may also pass --dataset_name/--bronze_bucket/--silver_bucket to override envs.
"""

import os
import re
import boto3
from pyspark.sql import SparkSession, Window
from pyspark.sql import functions as F
from pyspark.sql import types as T


# ---------------------------
# Spark bootstrap
# ---------------------------
def get_spark(app_name: str = "silver_breweries"):
    """
    Create a Spark session.
    """
    spark = (
        SparkSession.builder.appName(app_name)
        .config("spark.sql.session.timeZone", "UTC")
        .config("spark.sql.sources.partitionOverwriteMode", "dynamic")
        .getOrCreate()
    )
    return spark


# ---------------------------
# Discovery
# ---------------------------
def discover_latest_ingestion_date(bronze_bucket: str, dataset: str) -> str:
    """
    List S3 prefixes and return the latest run_date=YYYY-MM-DD under <dataset>/.

    Uses ListObjectsV2 with Delimiter='/' to read common prefixes like:
    <dataset>/run_date=2025-08-16/
    """
    s3 = boto3.client("s3")
    prefix = f"{dataset}/run_date="
    paginator = s3.get_paginator("list_objects_v2")
    rx = re.compile(rf"^{re.escape(dataset)}/run_date=(\d{{4}}-\d{{2}}-\d{{2}})/$")

    dates = []
    for page in paginator.paginate(Bucket=bronze_bucket, Prefix=prefix, Delimiter="/"):
        for cp in page.get("CommonPrefixes", []):
            p = cp.get("Prefix", "")
            m = rx.match(p)
            if m:
                dates.append(m.group(1))

    if not dates:
        raise RuntimeError(
            f"No run_date partitions found under s3://{bronze_bucket}/{dataset}/"
        )

    return max(dates)

# ---------------------------
# I/O helpers
# ---------------------------
def read_bronze(spark: SparkSession, bucket: str, dataset: str, ingestion_date: str):
    """
    Read Bronze JSON for the date from your Lambda layout:
    s3a://{bucket}/{dataset}/run_date={ingestion_date}/page=*/breweries.json
    """
    path = (
        f"s3a://{bucket}/{dataset}"
        f"/run_date={ingestion_date}/page=*/breweries.json"
        # f"/TEST-FAIL-run_date={ingestion_date}/page=*/breweries.json"
    )
    return (
        spark.read.option("multiLine", "true")  # arrays in the JSON files
        .option("mode", "PERMISSIVE")
        .json(path)
    )


def write_silver(df, bucket: str, dataset: str, ingestion_date: str):
    """
    Write Parquet partitioned by country/state under:
    s3a://{bucket}/{dataset}/ingestion_date={ingestion_date}
    """
    out = f"s3a://{bucket}/{dataset}/ingestion_date={ingestion_date}"
    (
        df.write.mode("overwrite")  # dynamic overwrite (only touched partitions)
        .partitionBy("country", "state")
        .parquet(out)
    )


# ---------------------------
# Transform
# ---------------------------
def transform(df):
    """
    Clean, cast, and deduplicate.
    """
    if df is None or len(df.columns) == 0:
        return df

    # Trim strings (only if present)
    str_cols = [
        "id", "name", "brewery_type", "street", "address_1", "address_2", "address_3",
        "city", "state", "state_province", "postal_code", "country",
        "phone", "website_url",
    ]
    for c in str_cols:
        if c in df.columns:
            df = df.withColumn(c, F.trim(F.col(c).cast(T.StringType())))

    # Cast coordinates
    df = (
        df.withColumn("latitude", F.col("latitude").cast(T.DoubleType()))
        .withColumn("longitude", F.col("longitude").cast(T.DoubleType()))
    )

    # Normalize location
    df = (
        df.withColumn("country", F.coalesce(F.col("country"), F.lit("Unknown")))
        .withColumn("state", F.coalesce(F.col("state"), F.lit("Unknown")))
    )

    # Deduplicate by id, prefer non-null updated_at then newest
    # If API lacks updated_at, this still provides stable de-dup.
    if "updated_at" in df.columns:
        order = Window.partitionBy("id").orderBy(
            F.col("updated_at").desc_nulls_last(),
            F.col("name").desc_nulls_last(),
        )
    else:
        order = Window.partitionBy("id").orderBy(F.col("name").desc_nulls_last())

    df = df.withColumn("rn", F.row_number().over(order)).where(F.col("rn") == 1).drop("rn")

    # Select a tidy schema (keep common fields; keep id as key)
    wanted = [
        "id", "name", "brewery_type", "street", "city", "state",
        "postal_code", "country", "longitude", "latitude",
        "phone", "website_url",
    ]
    keep = [c for c in wanted if c in df.columns]
    return df.select(*keep)



def main():
    dataset_name  = os.getenv("DATASET_NAME",  "openbrewerydb")
    bronze_bucket = os.getenv("BRONZE_BUCKET", "bees-lakehouse-bronze-dev")
    silver_bucket = os.getenv("SILVER_BUCKET", "bees-lakehouse-silver-dev")

    spark = get_spark()
    try:
        run_date = discover_latest_ingestion_date(bronze_bucket, dataset_name)
        print(f"[auto] discovered run_date={run_date}")

        raw_df = read_bronze(spark, bronze_bucket, dataset_name, run_date)
        tr_df  = transform(raw_df)
        write_silver(tr_df, silver_bucket, dataset_name, run_date)
        print(f"OK silver {run_date} rows={tr_df.count()}")
    finally:
        spark.stop()

if __name__ == "__main__":
    main()