# s3://.../scripts/glue/bronze_to_silver.py
import sys, argparse
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, lit, trim, upper, coalesce

def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--run_date", required=True)
    p.add_argument("--bronze_bucket", required=True)
    p.add_argument("--silver_bucket", required=True)
    return p.parse_args()

def main():
    args = parse_args()
    spark = (SparkSession.builder.appName("bronze_to_silver").getOrCreate())

    bronze_path = f"s3://{args.bronze_bucket}/openbrewerydb/run_date={args.run_date}/*.jsonl.gz"

    df = (spark.read
          .option("multiLine", False)
          .json(bronze_path))

    # Normalização leve (campos comuns da Open Brewery DB)
    cols = [
        "id","name","brewery_type","address_1","address_2","address_3",
        "city","state","county_province","postal_code","country",
        "longitude","latitude","phone","website_url"
    ]
    for c in cols:
        if c not in df.columns:
            df = df.withColumn(c, lit(None))

    dfn = (df
           .withColumn("country", upper(trim(coalesce(col("country"), lit("UNKNOWN")))))
           .withColumn("state",   upper(trim(coalesce(col("state"),   col("county_province"), lit("UNKNOWN")))))
           .withColumn("run_date", lit(args.run_date)))

    (dfn
     .repartition(1, "country","state")  # pequeno = 1 partição por região
     .write.mode("overwrite")
     .partitionBy("country","state","run_date")
     .parquet(f"s3://{args.silver_bucket}/breweries"))

    spark.stop()

if __name__ == "__main__":
    main()
