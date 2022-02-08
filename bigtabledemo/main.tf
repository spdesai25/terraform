variable "gcp_service_list" {
  description ="The list of apis necessary for the demo"
  type = list(string)
  default = ["bigquery.googleapis.com",
            "bigqueryconnection.googleapis.com",
            "bigquerystorage.googleapis.com",
            "storage-component.googleapis.com",
            "storage-api.googleapis.com"]
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

resource "google_storage_bucket_object" "datafile" {
  name = "airportdata"
  source = "https://storage.googleapis.com/cloud-samples-data/bigquery/flights/bq-flights-lax.csv"
  bucket = "${google_storage_bucket.bucket.name}"
}