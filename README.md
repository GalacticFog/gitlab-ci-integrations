# Gestalt Gitlab Integrations

## Overview

This example Gestalt Platform / Gitlab integration provides automatic deployments of Lambdas from Gitlab as part of the CI build process.  On build, Gitlab CI invokes Gestalt via REST API to create Lambda resources with exposed API endpoints in a target environment.  Optionally, Gestalt Platform may be configured to call back to Gitlab with the published endpoint for the deployed lambdas.

## Requirements

- GitLab, Gestalt Platform, and Amazon S3 with network connectivity between each.

## How to Use

In order to use this example, perform the following:


### 1) Configure Deployment Lambda

1) Create a Nashorn Lambda using the code from `example-gitlab-lambda-deploy.js`.  The Lambda must handle the POST method.  

2) Configure the following variables on the Lambda:

Required Variables:

    TARGET_ORG           FQON of the target org for deployment
    LAMBDA_PROVIDER_ID   UUID of the Lambda provider used for the lambda

Variables required by Gestalt SDK:

    META_URL             Internal URL for Meta service
    API_KEY              Meta API Key
    API_SECRET           Meta API Secret

Optional Variables (if set, enable callback to Gitlab to set the environment external url)

    GITLAB_API_URL       Gitlab API URL (e.g. 'https://gitlab.com/api/v4' for public gitlab).
    GITLAB_TOKEN         Access token for Gitlab API.  Required if GITLAB_API_URL is defined.
    API_GATEWAY_URL      URL of the API Gateway to form the Gitlab environment external URL.  Required if GITLAB_API_URL is defined.

3) Create an API endpoint for the lambda, and save the resulting URL for the Gitlab configuration step.

### 2) Create Target Gestalt Environment for Deployment from Gitlab project

1) In Gestalt, create or use an existing target environment (typically of type 'development') in the desired Org / Workspace.  Note the UUID of the Environment by navigating to the environment and expanding the details view - this is used in a later configuration step.

2) In the target environment, create an API (or use an existing API) and note the name for a later configuration step.


### 3) Configure Gitlab Project

From the desired Gitlab Project:

1) Copy `.gitlab-ci.yaml` to your Gitlab project.  If the project doesn't already have lambdas, you may copy `lambda1.py` and `lambda2.py` to the project as examples.

2) Configure the following variables

 Gitlab CI example for deploying a Lambda

 Variables typically defined in `gitlab-ci.yml`:

        LAMBDA_ARTIFACTS       Set to target the lambda artifact(s).  Examples: "lambda1.py", "lambda1.py lambda2.py", "*.py"
        LAMBDA_RUNTIME         Set to the lambda runtime type. Examples: python, nashorn, nodejs, python3, golang
        LAMBDA_API             Set to the Gestalt target API resource name
        LAMBDA_ENVIRONMENT_ID  Set to the Gestalt target Environment resource ID (Obtain from Gestalt > Environment > Expand Details)

 Variables typically defined as Gitlab CI Secret Variables:

 - AWS Variables (for uploading lambda artifact(s) to S3):

         AWS_ACCESS_KEY_ID      AWS access key (typically for service account)
         AWS_SECRET_ACCESS_KEY  AWS secret key (typically for service account)
         S3_BUCKET_NAME         Target AWS S3 bucket name

 - Gestalt Variables (for trigging Lambda create/update in Gestalt Platform)

         CI_URL                 Lambda deployment URL (Typically hosted by Gestalt Platform)
         GF_API_KEY             Gestalt service account key (if authentication is required)
         GF_API_SECRET          Gestalt service account secret (if authentication is required)

### 4) Perform a test build

Pushing a commit to the Git Repository should result in the CI/CD process defined by `.gitlab-ci.yml` to be executed.  To view the process, navigate to **Gitlab > CI/CD > Pipelines** and view the latest pipeline and deploy output.

Once the deploy stage of the pipeline completes successfully, navigate to Gestalt to view the deployed lambda(s).

## Files

### `ci-lambda-deploy.sh`

Two functions, deploy and stop.

**Deploy:** Uploads lambda artifacts to S3, and invokes the Gestalt deployment lambda to create/update lambda artifacts.

**Stop:** Invokes the Gestalt deployment lambda to delete/remove the lambda in Gestalt.

### `.gitlab-ci.yaml`

Sample Gitlab CI file for triggering deployments via `.ci-lambda-deploy.sh`.

The sample behavior of this file is:

**Automatically on Build:**

 - Deploy to a single 'Development' environment on commits to the master branch.  This creates corresponding Lambdas in Gestalt with the naming convention `<Gitlab project name>/master/<Lambda artifact name>`.

 - Deploy a 'review' environment for each commit to a sub-branch. This creates corresponding Lambdas in Gestalt with the naming convention `<Gitlab project name>/<branch name>/<Lambda artifact name>`.

**Manual Actions:**

 - Manual actions are provided for deploying and stopping environments.

### `example-gitlab-lambda-deploy.js`

A sample deployment lambda implementation that provides two functions: deploy and stop.  This lambda is triggered by the Gitlab CI process.

**Deploy:** Creates a Lambda and API endpoint resource in Gestalt.  Also, if Gitlab details (URL, credentials) are provided, a Gitlab environment is updated with an external URL to the lambda.  

(Note: a Gitlab environment can only have one external URL, if multiple lambdas belong to the same environment, the external URL will reflect the last lambda updated).

**Stop:** Deletes the lambda and API endpoint.
