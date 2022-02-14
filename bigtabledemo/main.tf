variable "gcp_service_list" {
  description ="The list of apis necessary for the demo"
  type = list(string)
  default = ["bigquery.googleapis.com",
            "bigqueryconnection.googleapis.com",
            "bigquerystorage.googleapis.com",
            "storage-component.googleapis.com",
            "storage-api.googleapis.com",
            "dataproc.googleapis.com"]
}

resource "google_project_service" "gcp_services" {
  for_each = toset(var.gcp_service_list)
  service = each.key
}

resource "random_uuid" "test" {
}

resource "google_storage_bucket" "bucket" {
  name   = "bigtabledemo-${random_uuid.test.result}"
  location = "US"
}

resource "google_storage_bucket_object" "datafiles" {
  
  for_each = fileset("./datasets/","*")
  name = "${each.value}"
  bucket = "${google_storage_bucket.bucket.name}"
  source = "./datasets/${each.value}"
}

resource "google_dataproc_cluster" "mycluster" {
  provider = google-beta
  name     = "biglake-demo-cluster"
  region = "us-central1"

  cluster_config {  
    gce_cluster_config{
        metadata = {
            bigquery-connector-url = "gs://spark-lib/bigquery/spark-bigquery-latest_2.12.jar" 
            spark-bigquery-connector-url = "gs://spark-lib/bigquery/spark-bigquery-latest_2.12.jar"           
        }
    }
    endpoint_config{
        enable_http_port_access = "true"
    }
    software_config {
      optional_components = ["ZEPPELIN"]
    }
    initialization_action {
      script      = "gs://goog-dataproc-initialization-actions-us-central1/connectors/connectors.sh"
      timeout_sec = 500
    }
  } 
}

/*
resource "google_bigquery_connection" "connection" {
    provider      = google-beta
    type = "CLOUD_RESOURCE"
    name = "my-connection"
}

resource "google_storage_bucket_object" "datafile" {
  name = "airportdata"
  source = "./datasets/airlines_data.csv"
  bucket = "${google_storage_bucket.bucket.name}"
}*/