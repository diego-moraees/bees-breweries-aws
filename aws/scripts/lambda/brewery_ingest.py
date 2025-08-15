import os, json, gzip, io, datetime, urllib.request, urllib.parse, boto3

S3 = boto3.client("s3")

API = "https://api.openbrewerydb.org/v1/breweries"
PER_PAGE = 200  # máximo suportado pela API

def fetch_page(page: int):
    url = API + "?" + urllib.parse.urlencode({"per_page": PER_PAGE, "page": page})
    with urllib.request.urlopen(url, timeout=15) as r:
        return json.loads(r.read().decode("utf-8"))

def lambda_handler(event, context):
    run_date = datetime.date.today().isoformat()
    bucket   = os.environ["BUCKET_NAME"]  # virá do Terraform
    prefix   = f"openbrewerydb/run_date={run_date}/"

    buf = io.BytesIO()
    with gzip.GzipFile(fileobj=buf, mode="wb") as gz:
        page = 1
        total = 0
        while True:
            data = fetch_page(page)
            if not data:
                break
            for rec in data:
                gz.write((json.dumps(rec, ensure_ascii=False) + "\n").encode("utf-8"))
                total += 1
            page += 1

    key = prefix + "breweries.jsonl.gz"
    S3.put_object(Bucket=bucket, Key=key, Body=buf.getvalue())

    return {"ok": True, "written_records": total, "s3_uri": f"s3://{bucket}/{key}"}
