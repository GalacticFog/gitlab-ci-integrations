#!/bin/bash

## Example for deploying a lambda from Gitlab.  This script performs the following
## - Checks for required variables and tool dependencies
## - For each lambda artifact - Upload the lambda file to S3, and
## - Publishes to Gestalt Platform to create/update the lambda resource with the S3 URL

. .ci-functions.sh

[ ! -z $GF_API_KEY ] && [ -z $GF_API_SECRET ] && exit_with_error "GF_API_KEY provided, but GF_API_SECRET missing"

check_for_required_environment_variables \
    S3_BUCKET_NAME \
    CI_URL \
    CI_COMMIT_SHA \
    CI_COMMIT_REF_SLUG \
    CI_PROJECT_NAME \
    LAMBDA_ARTIFACTS \
    LAMBDA_API \
    LAMBDA_ENVIRONMENT_ID

check_for_required_tools \
    curl \
    base64

deploy() {
    check_for_required_tools \
        aws

    for lambda in $LAMBDA_ARTIFACTS; do

        echo "Processing lambda '$lambda'"

        # Upload lambda artifact to S3
        echo "Uploading lambda '$lambda' to S3..."
        aws s3 cp $lambda s3://$S3_BUCKET_NAME/$CI_PROJECT_NAME/ --acl public-read
        if [ $? -eq 0 ]; then

            # Build JSON payload for 'package' lambda
            payload=$( printf '{"file":"%s", "runtime":"%s", "api":"%s", "env_id": "%s", "project":"%s", "project_path":"%s", "git_env":"%s", "lambda_url":"%s", "git_ref":"%s", "git_sha":"%s"}\n' \
              "$lambda" \
              "$LAMBDA_RUNTIME" \
              "$LAMBDA_API" \
              "$LAMBDA_ENVIRONMENT_ID" \
              "$CI_PROJECT_NAME" \
              "$CI_PROJECT_PATH" \
              "$CI_ENVIRONMENT_NAME" \
              "https://s3.amazonaws.com/$S3_BUCKET_NAME/$CI_PROJECT_NAME/$lambda" \
              "$CI_COMMIT_REF_SLUG" \
              "$CI_COMMIT_SHA"
            )

            # POST information to Lambda deployment service
            echo "Deploying lambda '$lambda' to Gestalt Platform..."
            call_gestalt
        else
            echo "Lambda '$lambda' upload to S3 failed!"
        fi

    done
    echo Done.
}

stop() {
    for lambda in $LAMBDA_ARTIFACTS; do

        echo "Processing lambda '$lambda'"

        # Build JSON payload for 'package' lambda
        payload=$( printf '{"action":"stop", "file":"%s", "runtime":"%s", "api":"%s", "env_id": "%s", "project":"%s", "project_path":"%s", "git_env":"%s", "git_ref":"%s", "git_sha":"%s"}\n' \
          "$lambda" \
          "$LAMBDA_RUNTIME" \
          "$LAMBDA_API" \
          "$LAMBDA_ENVIRONMENT_ID" \
          "$CI_PROJECT_NAME" \
          "$CI_PROJECT_PATH" \
          "$CI_ENVIRONMENT_NAME" \
          "$CI_COMMIT_REF_SLUG" \
          "$CI_COMMIT_SHA"
        )

        # POST information to Lambda deployment service
        echo "Deploying lambda '$lambda' to Gestalt Platform..."
        call_gestalt
    done
    echo Done.
}

call_gestalt() {
    if [ -z $GF_API_KEY ]; then
        [ ! -z $DEBUG ] && echo curl -X POST -d "$payload" -H 'Content-Type: application/json' $CI_URL
        curl -X POST -d "$payload" -H 'Content-Type: application/json' $CI_URL  2>/dev/null
    else
        [ ! -z $DEBUG ] && echo curl -u "$GF_API_KEY":"*****" -X POST -d "$payload" -H 'Content-Type: application/json' $CI_URL
        curl -u "$GF_API_KEY":"$GF_API_SECRET" -X POST -d "$payload" -H 'Content-Type: application/json' $CI_URL  2>/dev/null
    fi

    if [ $? -ne 0 ]; then
        echo "Error: Lambda deploy failed!"
    fi
}

if [ "$1" == "stop" ]; then
    stop
else
    deploy
fi
