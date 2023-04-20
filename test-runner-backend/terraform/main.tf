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

# Define and deploy a tasks queue
# Queue should not be named the same as any other queue created 7 days before within the same GCP account. It will throw an error.
resource "google_cloud_tasks_queue" "test_runner_tasks_queue" {
  name     = "test-runner-tasks-queue-v3"
  location = var.region

  rate_limits {
    max_concurrent_dispatches = 1
  }

  retry_config {
    max_attempts = 1
  }

  depends_on = [google_project_service.cloud_tasks_api]
}

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

# Create a firewall rule to allow http communication to compute instance.
resource "google_compute_firewall" "rules" {
  project     = local.project_id
  name        = "allow-http-firewall-rule-v2"
  network     = "default"
  description = "Creates firewall rule targeting tagged instances"

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "1000-2000"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]

  depends_on    = [google_project_service.compute_engine_api]
}


## 
## DOCKER CONTAINER REGISTRY
##
resource "google_artifact_registry_repository" "repo" {
  project       = local.project_id
  location      = var.region
	format        = "DOCKER"
	repository_id = "repo"
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
resource "null_resource" "pull_and_push_superset" {

  provisioner "local-exec" {
    command = <<-EOT
			gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://${var.region}-docker.pkg.dev
      docker pull ${local.superset_local_image}
      docker tag ${local.superset_local_image} ${local.superset_remote_image}
      docker push ${local.superset_remote_image}
    EOT
  }
  depends_on = [
    google_artifact_registry_repository.repo,
  ]
}


##
## RUN SUPERSET FRONTEND
##
resource "google_cloud_run_service" "superset" {
  name     = "cloudrun-superset"
  location = var.region

  template {
    spec {
      containers {
        image = local.superset_remote_image
				env {
					name = "SUPERSET_SECRET_KEY"
					value = local.credjson.private_key
				}
				ports {
					container_port = 8088 
				}
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

	depends_on = [
		null_resource.pull_and_push_superset,
	]
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.superset.location
  project     = google_cloud_run_service.superset.project
  service     = google_cloud_run_service.superset.name

  policy_data = data.google_iam_policy.noauth.policy_data

}
