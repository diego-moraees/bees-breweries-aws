from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator

default_args = {
    "owner": "data-eng",
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5)
}

with DAG(
        dag_id="brewery_ingest_dag",
        default_args=default_args,
        schedule_interval="@daily",
        start_date=datetime(2025, 8, 1),
        catchup=False,
        tags=["bees", "breweries"],
) as dag:

    hello = BashOperator(
        task_id="hello",
        bash_command="echo 'Airflow is up! 🍺'"
    )

    hello
