The main.tf file deploys the following on a GCP project,
    (1) Enable the necessary APIs on the project.
    (2) Create a GCS bucket and upload sample data files in it from ./datasets.
    (3) Create a BigQuery dataset.
    (4) Deploy a dataproc cluster with Zeppelin and https port access enabled.

The ./scripts contains BigQuery scripts for the following,
    (1) Create external table using the Cloud Connection.
    (2) Sample queries for data retrieval.
    (3) Create row access policy. 