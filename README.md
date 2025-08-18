# Bees Breweries Lakehouse (AWS)

A small, end‑to‑end **data lakehouse** on AWS that ingests brewery data and builds curated analytical layers.
The project uses **S3 (Bronze/Silver/Gold)**, **AWS Glue** (ETL; Delta write on Gold), **Step Functions** (orchestration),
**EventBridge + SNS** (alerts), and **Athena + Glue Data Catalog** (SQL access). Everything is created with **Terraform**.

---

## What this project does

- **Bronze**: a Lambda fetches data from the Breweries API and lands JSON on S3 by `run_date=YYYY-MM-DD/page=*`.
- **Silver**: a Glue job cleans/normalizes JSON into **Parquet**, partitioned by `ingestion_date`, `country`, `state`.
- **Gold**: a Glue job aggregates counts by `(country, state, brewery_type)` and writes **Delta Lake** partitions.
- **Orchestration**: Step Functions runs `Lambda → Glue Silver → Glue Gold` with sensible retry/backoff.
- **Monitoring**: EventBridge rules watch Glue & Step Functions failures and publish short messages to an **SNS** topic.
- **Query**: Athena (via Glue Data Catalog tables) lets you query Silver (Parquet) and Gold (Delta) with SQL.

---

## Architecture (high level)

![aws-breweries-archtecture.png](images/aws-breweries-archtecture.png)

---

## Repository layout (short)

```
aws/
  us-east-1/
    infraestructure/
      *.tf (root stack: Step Functions, EventBridge, SNS, Athena, Glue DB/Tables, etc.)
      envs/
        dev.tfvars  ← your environment variables (see below)
    modules/
      ... reusable Terraform modules (s3, glue_job, sfn_state_machine, glue_catalog, etc.)
scripts/
  glue/
    bronze_to_silver.py
    silver_to_gold_delta.py
```

> Folder name is **infraestructure** (as in this repo).

---

## Prerequisites

- AWS account with permissions for S3, Lambda, Glue, Step Functions, EventBridge, SNS, Athena/Glue Catalog.
- AWS CLI configured (or credentials provided via Terraform variables as shown below).
- Terraform v1.5+.

---

## 1) Create `dev.tfvars` (inside `envs/`)

Create the file:
`aws/us-east-1/infraestructure/envs/dev.tfvars`

Use **exactly** these variables (fill in your keys if you’re not using an AWS profile/role):

```hcl
bucket     = "rp-lakehouse-dev-terraform-states-bucket"
region     = "us-east-1"

#Add your AWS credentials 
access_key = ""
secret_key = ""

#Set your buckets 
bees_s3_bronze  = "bees-lakehouse-bronze"
bees_s3_silver  = "bees-lakehouse-silver"
bees_s3_gold    = "bees-lakehouse-gold"
bees_s3_scripts = "bees-lakehouse-scripts"
```

> The `bucket` must exist (S3 bucket for Terraform state). If it doesn’t, create it first. 

---

## 2) Deploy with Terraform

From the root stack folder:

```bash
cd aws/us-east-1/infraestructure

terraform init
terraform plan  -var-file=envs/dev.tfvars
terraform apply -var-file=envs/dev.tfvars -auto-approve
```

What this creates: S3 buckets (if included), IAM roles/policies, Lambda (ingest), Glue jobs (Silver/Gold),
Step Functions state machine, EventBridge rules, SNS topic/subscription, Athena workgroup (and Glue catalog DB/tables).
Obs.: You must change also the alert_email variable setting your email to get the msgs from sns.
---

## 3) Run the pipeline

Open **AWS Step Functions** → State Machine named like `breweries-pipeline-dev` → **Start execution** with `{}`.

(Or CLI: `aws stepfunctions start-execution --state-machine-arn <your-sfn-arn>`)

---

## 4) Explore the data in S3

- Bronze: `s3://bees-lakehouse-bronze-<env>/<dataset>/run_date=YYYY-MM-DD/page=*/breweries.json`
- Silver: `s3://bees-lakehouse-silver-<env>/<dataset>/ingestion_date=YYYY-MM-DD/country=.../state=.../*.parquet`
- Gold:   `s3://bees-lakehouse-gold-<env>/<dataset>/` with `_delta_log/` and partitions by date/country/state.

---

## 5) Query with Athena

- In **Athena**, switch to the workgroup created by Terraform (commonly `breweries-athena-wg`).
- Use the Glue databases/tables created by Terraform (e.g., `db_silver.open_breweries`, `db_gold.open_breweries_agg`).

Example queries:

```sql
-- Silver preview
SELECT *
FROM db_silver.open_breweries
WHERE ingestion_date = '2025-08-16'
LIMIT 20;

-- Gold (Delta): top brewery types per state
SELECT state, brewery_type, SUM(breweries_count) AS total
FROM db_gold.open_breweries_agg
WHERE ingestion_date = '2025-08-16' AND country = 'United States'
GROUP BY state, brewery_type
ORDER BY state, total DESC;
```

If you see “No output location provided”, open the Athena console and ensure the workgroup has a **Query result location** configured (Terraform does this in this project).

---

## Alerts (failures)

You’ll get **one concise email** if Lambda, a Glue job, or the State Machine fails.
To change recipients, update the **SNS subscription** in Terraform.

Example body:

```
[ALERT] Glue job openbrewerydb-silver-to-gold is FAILED at 2025-08-16T02:34:56Z.
JobRunId: jr_1234567890
Account: 123456789012 | Region: us-east-1
```

---

## Clean up

From `aws/us-east-1/infraestructure`:

```bash
terraform destroy -var-file=envs/dev.tfvars
```

> If S3 buckets are not empty, empty them first (or enable force-destroy in those modules, if available).

---

## Troubleshooting

- **Zero rows in Athena (Gold)**: make sure the date you query exists; if you are not using a crawler or projection, run `MSCK REPAIR TABLE db_gold.open_breweries_agg;`.
- **Duplicate alert emails**: the EventBridge rules are scoped to one message per failure; if you add rules, keep filters tight.
- **Credentials**: you can leave `access_key/secret_key` empty when using a configured AWS CLI profile/role.
