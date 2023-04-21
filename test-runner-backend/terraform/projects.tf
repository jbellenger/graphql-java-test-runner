# Enable cloud resource manager API, required to enable dependent API's.
resource "google_project_service" "cloud_manager_api" {
  service                    = "cloudresourcemanager.googleapis.com"
  disable_dependent_services = true
}

# Enable Workflows API
# resource "google_project_service" "workflows" {
#   service                    = "workflows.googleapis.com"
#   disable_dependent_services = true
#   depends_on                 = [google_project_service.cloud_manager_api]
# }

# Enable AppEngine API - required to create datastore
resource "google_project_service" "app_engine_api" {
  service                    = "appengine.googleapis.com"
  disable_dependent_services = true
  depends_on                 = [google_project_service.cloud_manager_api]
}

# JMB TODO: I think this isn't needed if we're running in cloud run
# Enable ComputeEngine API - required to create compute engine instance
# resource "google_project_service" "compute_engine_api" {
#   service                    = "compute.googleapis.com"
#   disable_dependent_services = true
#   depends_on                 = [google_project_service.cloud_manager_api]
# }

# JMB TODO: let's see if we can use BQ on superset
# # Enable Cloud Firestore API - required to communicate to firestore via workflow and test-runner
# resource "google_project_service" "firestore_api" {
#   service                    = "firestore.googleapis.com"
#   disable_dependent_services = true
# }

# JMB TODO: why is this needed? Also repeated above
# resource "google_project_service" "compute_api" {
#   service                    = "compute.googleapis.com"
#   disable_dependent_services = true
# }

# Enable BigQuery API - required for storing benchmark results
resource "google_project_service" "bigquery_api" {
  service                    = "bigquery.googleapis.com"
  disable_dependent_services = true
}

# Enable ArtifactRegistry - required for managing docker containers for apache superset
resource "google_project_service" "artifactregistry_api" {
  service                    = "artifactregistry.googleapis.com"
  disable_dependent_services = true
}

# Enable CloudRun - required for running apache superset docker container
resource "google_project_service" "run_api" {
  service                    = "run.googleapis.com"
  disable_dependent_services = true
}

# Enable IAM - required for creating specialized service accounts for reading/writing 
# benchmark results
resource "google_project_service" "iam_api" {
  service                    = "iam.googleapis.com"
  disable_dependent_services = true
}
