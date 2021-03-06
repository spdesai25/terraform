//define a variable with list of GCP services to be enabled
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

//datasource to collect project info 
data "google_project" "project" {
}

//module to enable the required GCP services
resource "google_project_service" "gcp_services" {
  for_each = toset(var.gcp_service_list)
  service = each.key
  disable_dependent_services = true
}

resource "random_uuid" "test" {
}

//module to create GCS bucket for hosting data files
resource "google_storage_bucket" "bucket" {
  name   = "bigtabledemo-${random_uuid.test.result}"
  location = "US"
  uniform_bucket_level_access = true
  depends_on = [
    google_project_service.gcp_services
  ]
}

//module to load datafiles into the GCS bucket
resource "google_storage_bucket_object" "datafiles" {
  
  for_each = fileset("./datasets/","*")
  name = "${each.value}"
  bucket = "${google_storage_bucket.bucket.name}"
  source = "./datasets/${each.value}"
  depends_on = [
    google_storage_bucket.bucket
  ]
}

//module to create a bq dataset
resource "google_bigquery_dataset" "dataset" {
  dataset_id                  = "bigtable_demo"
  friendly_name               = "demo"
  description                 = "This is a bigtable demo dataset"
  location                    = "US"
    depends_on = [
    google_project_service.gcp_services
  ]
}

//module to create a service account
resource "google_service_account" "sa-name" {
  account_id = "sa-name"
  display_name = "SA"
}

//module to bind the dataproc worker role to the service account
resource "google_project_iam_member" "dataproc_worker_binding" {
  project = data.google_project.project.number
  role    = "roles/dataproc.worker"
  member  = "serviceAccount:${google_service_account.sa-name.email}"
}

//module to bind the bq roles to the service account
resource "google_project_iam_member" "bigquery_binding" {
  project = data.google_project.project.number
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${google_service_account.sa-name.email}"
}

//module to create a network for dataproc to spin up GCE instances
resource "google_compute_network" "dataproc_network" {
  name                    = "dataproc-network"
  auto_create_subnetworks = false
}

//module to create subnetwork with private google access enabled
resource "google_compute_subnetwork" "network-with-private-ip-google-access" {
  name          = "dataproc-subnetwork"
  ip_cidr_range = "10.2.0.0/16"
  region        = "us-central1"
  network       = google_compute_network.dataproc_network.id
  private_ip_google_access = true  
  secondary_ip_range {
    range_name    = "tf-test-secondary-range-update1"
    ip_cidr_range = "192.168.10.0/24"
  }
}

//module to create the dataproc cluster with Zeppelin and https endpoints enabled
resource "google_dataproc_cluster" "mycluster" {
  provider = google-beta
  name     = "biglake-demo-cluster"
  region = "us-central1"
  depends_on = [
    google_project_service.gcp_services
  ]
  cluster_config {    
    gce_cluster_config{
        service_account = "${google_service_account.sa-name.email}"
        subnetwork = google_compute_subnetwork.network-with-private-ip-google-access.name
        internal_ip_only = true 
        shielded_instance_config {
            enable_secure_boot = true
            enable_integrity_monitoring = true
            enable_vtpm = true          
        }       
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
      override_properties = {
        "dataproc:dataproc.allow.zero.workers" = "true"
      }
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