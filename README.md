# bees-breweries-aws
AWS-based data pipeline for the BEES Breweries case. Extracts data from the Open Brewery DB API, stores it in an S3 data lake using the medallion architecture (bronze, silver, gold), and orchestrates with MWAA. Infrastructure managed with Terraform.
