#!/bin/bash
## create a new service account for running workflows

export SERVICE_ACCOUNT=workflows-sa
export PROJECT_ID=$(gcloud config list --format 'value(core.project)')

gcloud iam service-accounts create ${SERVICE_ACCOUNT}

## allow workflow-sa to invoke cloud run 

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role "roles/run.invoker"

## install cloud functions

PERM="roles/cloudfunctions.invoker"

cd randomgen/

gcloud beta functions deploy randomgen \
    --region "us-east1" \
    --gen2 \
    --runtime python39 \
    --trigger-http \
    --entry-point randomgen 

gcloud beta functions add-iam-policy-binding "randomgen" --region "us-east1" --member=serviceAccount:${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com --role=${PERM} --gen2

cd ../multiply/

gcloud beta functions deploy multiply \
    --region "us-east1" \
    --gen2 \
    --runtime python39 \
    --trigger-http \
    --entry-point multiply 

gcloud beta functions add-iam-policy-binding "multiply" --region "us-east1" --member=serviceAccount:${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com --role=${PERM} --gen2

cd ..

gcloud workflows deploy workflow \
    --location="us-east1" \
    --source=workflow.yaml \
    --service-account=${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com

gcloud workflows execute workflow --location="us-east1"