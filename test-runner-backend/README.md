# JMB TODOs
  - cleanup backend readme
  - re-examine aws vs gcp
  - write new top-level readme

# GraphQL Java Test Runner

Discuss and ask questions in our Discussions: https://github.com/graphql-java/graphql-java/discussions

This is a test runner application to measure the performance of [GraphQL](https://github.com/graphql/graphql-spec) Java implementation.

### Terraform and GCP project Setup

This project uses terraform to manage testing infrastructure in GCP.

1. Cloud Tasks Queue.
1. Workflow.
1. Compute Engine.
1. Firestore.

Setup: 

  1. Install terraform from [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
  1. Create a new gcp project.
  1. Add a billing account to the above created project.
  1. Enable these services on the project (APIs & Services -> Library):
    - [Compute Engine API](https://console.cloud.google.com/apis/library/compute.googleapis.com)
    - [Google Cloud Firestore API](https://console.cloud.google.com/apis/library/firestore.googleapis.com)
    - [App Engine Admin API](https://console.cloud.google.com/apis/library/appengine.googleapis.com)
  1. Create service account on IAM & Admin->Service Account-> Create Service Account.
  1. Create a key for the service account. From the service account, select Keys -> Add Key -> Create new key -> Json
  1. Move the downloaded service account key to the terraform directory and rename it to `cred.json`.
  1. Assign the role Basic -> Owner to the new service account. This is done on IAM -> 'Manage Resources' -> YOUR_PROJECT_NAME -> Add Principal. Add the email of the service account and select role "Basic -> Owner".
     The Owner (rather than Editor) role is required to create the firestore that holds test results.
  1. In the terraform directory, run:
  
    ```
    $ terraform init
    $ terraform apply
    ```

Terraform will create all the permanent infrastructure required by the test runner. This infra fits within the GCP 
free tier and can run forever.

### React App

#### Installation

* In your terminal cd to test-runner-frontend folder.
* Run ```npm install``` to install all dependencies.

#### Run the app locally

* In your terminal cd to test-runner-frontend folder.
* Run ```npm start``` to run the app locally, then open this URL on your browser: http://localhost:3000/graphql-java-test-runner.
* To look at the code, just open up the project in your favorite code editor.

#### Run tests

* In your terminal cd to test-runner-frontend folder.
* To run all tests run ```npm tests```.
* To run all tests with coverage precentage run ```npm test -- --coverage```.

#### Deployment

* In your terminal cd to test-runner-frontend folder.
* Run ```npm run deploy```, then open this URL on your browser: https://adarsh-jaiswal.github.io/graphql-java-test-runner/
* NOTE: Changes might take up to 10 minutes to reflect.