# s3://.../scripts/glue/silver_to_gold.py
import sys, argparse
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, count, lit

def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--run_date", required=True)
    p.add_argument("--silver_bucket", required=True)
    p.add_argument("--gold_bucket", required=True)
    return p.parse_args()

def main():
    args = parse_args()
    spark = (SparkSession.builder.appName("silver_to_gold").getOrCreate())

    silver = f"s3://{args.silver_bucket}/breweries/*/*/run_date={args.run_date}/*"
    df = spark.read.parquet(silver)

    agg = (df.groupBy("brewery_type","country","state")
           .agg(count(lit(1)).alias("qty"))
           )

    (agg.coalesce(1)
     .write.mode("overwrite")
     .partitionBy("run_date")
     .parquet(f"s3://{args.gold_bucket}/breweries_agg/run_date={args.run_date}"))

    spark.stop()

if __name__ == "__main__":
    main()
