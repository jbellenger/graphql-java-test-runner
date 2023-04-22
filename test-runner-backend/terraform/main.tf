terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

locals {
  cred  = file("cred.json")
  credjson = jsondecode(local.cred)
  project_id = local.credjson.project_id
  email = local.credjson.client_email

  superset_local_image = "apache/superset:${var.superset_docker_tag}"
  superset_remote_image = "${var.region}-docker.pkg.dev/${local.project_id}/repo/superset:${var.superset_docker_tag}"
  superset_secret_key = local.credjson.private_key
}

provider "google" {
  credentials = local.cred
  project     = local.project_id
  region      = var.region
  zone        = "us-central1-c"
}

# Define and deploy a workflow
# JMB TODO: not sure this is needed, plus it fails because it can't find
# workflow.yaml -- I think I might have moved it somewhere
# resource "google_workflows_workflow" "test_runner_workflow" {
#   name            = "test-runner-workflow-v2"
#   region          = var.region
#   description     = "Test runner workflow"
#   service_account = local.email
#   source_contents = file("workflow.yaml")
# 
#   depends_on = [google_project_service.workflows]
# }

# Create Firestore, this operation will be successful when initializing
# the project for the first time. Firestore once created can never be destroyed on the same project.
# If terraform apply is called multiple times for the same project it's ok to get the below error for firestore.
# Error 409: This application already exists and cannot be re-created.
resource "google_app_engine_application" "firestore" {
  project       = local.project_id
  location_id   = "us-central"
  database_type = "CLOUD_FIRESTORE"

  depends_on = [google_project_service.app_engine_api]
}

# JMB TODO: I think this isn't needed if we're running in cloud run
# Create a firewall rule to allow http communication to compute instance.
# resource "google_compute_firewall" "rules" {
#   project     = local.project_id
#   name        = "allow-http-firewall-rule-v2"
#   network     = "default"
#   description = "Creates firewall rule targeting tagged instances"
# 
#   allow {
#     protocol = "tcp"
#     ports    = ["80", "8080", "1000-2000"]
#   }
#   source_ranges = ["0.0.0.0/0"]
#   target_tags   = ["web"]
# 
#   depends_on    = [google_project_service.compute_engine_api]
# }

## 
## BIGQUERY FOR STORING TEST RESULTS
##
resource "google_bigquery_dataset" "test_results" {
  dataset_id = "test_results"
  friendly_name = "test results"
  location = "us-central1"

  access {
    role = "roles/bigquery.dataOwner"
    user_by_email = google_service_account.results_publisher.email
  }

  # even though our service account has the OWNER role, bigquery admin is not granted by default
  access {
    role = "roles/bigquery.admin"
    user_by_email = local.credjson.client_email
  }
  access {
    role = "roles/bigquery.dataOwner"
    user_by_email = local.credjson.client_email
  }

  depends_on = [google_project_service.bigquery_api]
}

resource "google_bigquery_table" "runs" {
  dataset_id = google_bigquery_dataset.test_results.dataset_id
  table_id = "runs"
  schema = <<-EOT
    [
      {
        "name": "gitsha",
        "type": "STRING",
        "mode": "NULLABLE",
        "description": "git sha that the test results were run against"
      },
      {
        "name": "jmh_json",
        "type": "JSON",
        "mode": "NULLABLE",
        "description": "raw JSON output of jmh describing the test results"
      },
      {
        "name": "stamp",
        "type": "TIMESTAMP",
        "mode": "REQUIRED"
      }
    ]
    EOT
}



##
## SERVICE ACCOUNT FOR POSTING TEST RESULTS FROM GITHUB
##
resource "google_service_account" "results_publisher" {
  account_id   = "results-publisher"
  display_name = "results publisher"

  depends_on = [google_project_service.iam_api]
}

resource "google_project_iam_member" "results_publisher_bigquery_iam" {
  project = local.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.results_publisher.email}"
}

# JMB TODO: not needed if we use bigquery
# resource "google_project_iam_member" "results_publisher_firestore_iam" {
#   project = local.project_id
#   role    = "roles/firestore.serviceAgent"
#   member  = "serviceAccount:${google_service_account.results_publisher.email}"
# }


## 
## DOCKER CONTAINER REGISTRY
##
resource "google_artifact_registry_repository" "repo" {
  project       = local.project_id
  location      = var.region
  format        = "DOCKER"
  repository_id = "repo"

  depends_on = [google_project_service.artifactregistry_api]
}

data "google_iam_policy" "admin" {
  binding {
    role = "roles/artifactregistry.admin"
    members = [
      "serviceAccount:${local.email}"
    ]
  }
}
 
resource "google_artifact_registry_repository_iam_policy" "policy" {
  project = google_artifact_registry_repository.repo.project
  location = google_artifact_registry_repository.repo.location
  repository = google_artifact_registry_repository.repo.name

  policy_data = data.google_iam_policy.admin.policy_data
}


## 
## SUPERSET DOCKER IMAGE PUBLISHING
##
# resource "null_resource" "pull_and_push_superset" {
# 
#   provisioner "local-exec" {
#     command = <<-EOT
#       gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://${var.region}-docker.pkg.dev
#       docker pull ${local.superset_local_image}
#       docker tag ${local.superset_local_image} ${local.superset_remote_image}
#       docker push ${local.superset_remote_image}
#     EOT
#   }
#   depends_on = [
#     google_artifact_registry_repository.repo,
#   ]
# }


##
## RUN SUPERSET FRONTEND
##
# resource "google_cloud_run_service" "superset" {
#   name     = "cloudrun-superset"
#   location = var.region
# 
#   template {
#     spec {
#       containers {
#         image = local.superset_remote_image
#         env {
#           name = "SUPERSET_SECRET_KEY"
#           value = local.credjson.private_key
#         }
#         ports {
#           container_port = 8088 
#         }
#       }
#     }
#   }
# 
#   traffic {
#     percent         = 100
#     latest_revision = true
#   }
# 
#   depends_on = [
#     null_resource.pull_and_push_superset,
#     google_project_service.run_api
#   ]
# }
# 
# data "google_iam_policy" "noauth" {
#   binding {
#     role = "roles/run.invoker"
#     members = [
#       "allUsers",
#     ]
#   }
# }
# 
# resource "google_cloud_run_service_iam_policy" "noauth" {
#   location    = google_cloud_run_service.superset.location
#   project     = google_cloud_run_service.superset.project
#   service     = google_cloud_run_service.superset.name
# 
#   policy_data = data.google_iam_policy.noauth.policy_data
# }
