import os, json, datetime, time, urllib.request, urllib.parse, boto3

S3 = boto3.client("s3")

API = "https://api.openbrewerydb.org/v1/breweries"
PER_PAGE = int(os.getenv("PER_PAGE", "200"))       # pode ajustar por env var
REQUEST_SLEEP = float(os.getenv("REQUEST_SLEEP", "0.2"))  # pausa leve entre páginas

def fetch_page(page: int):
    params = {"per_page": PER_PAGE, "page": page}
    url = API + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": "OBDB-Ingest/1.0 (+ingest)",
            "Accept": "application/json",
            "Referer": "https://www.openbrewerydb.org/",
        },
    )
    with urllib.request.urlopen(req, timeout=15) as r:
        return json.loads(r.read().decode("utf-8"))

def lambda_handler(event, context):
    run_date = datetime.date.today().isoformat()
    bucket   = os.environ["BUCKET_NAME"]
    base     = f"openbrewerydb/run_date={run_date}/"

    total_records = 0
    pages_written = 0
    page = 1

    while True:
        data = fetch_page(page)
        if not data:
            break

        body = json.dumps(data, ensure_ascii=False).encode("utf-8")
        key  = f"{base}page={page:04d}/breweries.json"

        S3.put_object(
            Bucket=bucket,
            Key=key,
            Body=body,
            ContentType="application/json"
        )

        total_records += len(data)
        pages_written += 1
        page += 1
        if REQUEST_SLEEP > 0:
            time.sleep(REQUEST_SLEEP)

    # Manifesto com metadados da ingestão
    manifest = {
        "run_date": run_date,
        "per_page": PER_PAGE,
        "pages": pages_written,
        "records": total_records,
    }
    S3.put_object(
        Bucket=bucket,
        Key=f"{base}manifest.json",
        Body=json.dumps(manifest).encode("utf-8"),
        ContentType="application/json",
    )

    return {
        "ok": True,
        "pages": pages_written,
        "records": total_records,
        "prefix": f"s3://{bucket}/{base}"
    }
