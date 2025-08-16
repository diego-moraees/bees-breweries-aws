"""
Transform breweries JSON landed in the Bronze layer into a cleaned,
columnar Silver layer (Parquet) partitioned by country and state.

This script:
1) Reads the Bronze JSON for a given `ingestion_date`.
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
- We accept --ingestion_date YYYY-MM-DD (required).
- You may also pass --dataset_name/--bronze_bucket/--silver_bucket to override envs.
"""

import os
import sys
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
        "id", "name", "brewery_type", "street",
        "address_1", "address_2", "address_3",
        "city", "state", "state_province", "county_province",
        "postal_code", "country",
        "phone", "website_url",
    ]
    for c in str_cols:
        if c in df.columns:
            df = df.withColumn(c, F.trim(F.col(c).cast(T.StringType())))

    # Cast coordinates
    if "latitude" in df.columns:
        df = df.withColumn("latitude", F.col("latitude").cast(T.DoubleType()))
    if "longitude" in df.columns:
        df = df.withColumn("longitude", F.col("longitude").cast(T.DoubleType()))

    # Normalize location
    # If state is missing, try state_province/county_province; fallback to "Unknown"
    state_expr = F.coalesce(
        F.col("state"),
        F.col("state_province"),
        F.col("county_province"),
        F.lit("Unknown"),
    )
    df = (
        df.withColumn("country", F.coalesce(F.col("country"), F.lit("Unknown")))
        .withColumn("state", state_expr)
    )

    # Deduplicate by id (keep "latest"):
    # Prefer: updated_at desc (if available), then name desc (stable tiebreaker)
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


# ---------------------------
# Entrypoint
# ---------------------------
def main(ingestion_date: str, dataset_name: str, bronze_bucket: str, silver_bucket: str):
    spark = get_spark()
    try:
        raw_df = read_bronze(spark, bronze_bucket, dataset_name, ingestion_date)
        tr_df = transform(raw_df)
        write_silver(tr_df, silver_bucket, dataset_name, ingestion_date)
        print(f"OK silver {ingestion_date} rows={tr_df.count()}")
    finally:
        spark.stop()


if __name__ == "__main__":
    # Required: --ingestion_date YYYY-MM-DD
    # Optional: --dataset_name, --bronze_bucket, --silver_bucket
    if len(sys.argv) >= 3 and sys.argv[1] == "--ingestion_date":
        ingestion_date = sys.argv[2]

        dataset_name  = os.getenv("DATASET_NAME",  "openbrewerydb")
        bronze_bucket = os.getenv("BRONZE_BUCKET", "bees-lakehouse-bronze-dev")
        silver_bucket = os.getenv("SILVER_BUCKET", "bees-lakehouse-silver-dev")

        # Allow overriding envs via Glue args if provided
        if "--dataset_name" in sys.argv:
            dataset_name = sys.argv[sys.argv.index("--dataset_name") + 1]
        if "--bronze_bucket" in sys.argv:
            bronze_bucket = sys.argv[sys.argv.index("--bronze_bucket") + 1]
        if "--silver_bucket" in sys.argv:
            silver_bucket = sys.argv[sys.argv.index("--silver_bucket") + 1]

        main(ingestion_date, dataset_name, bronze_bucket, silver_bucket)
    else:
        raise SystemExit("Usage: bronze_to_silver.py --ingestion_date YYYY-MM-DD "
                         "[--dataset_name <name>] [--bronze_bucket <bucket>] [--silver_bucket <bucket>]")
