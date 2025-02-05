#!/bin/bash

# Set variables
RESOURCE_GROUP="kahfads-common"
STORAGE_ACCOUNT_NAME="adsterraformstates"
CONTAINER_NAME="production"
BLOB_NAME="terraform.tfvars"
DOWNLOAD_PATH="./terraform.tfvars"

# Login to Azure (if not already logged in)
az login --output none

# Download the blob
az storage blob download \
    --account-name $STORAGE_ACCOUNT_NAME \
    --container-name $CONTAINER_NAME \
    --name $BLOB_NAME \
    --file $DOWNLOAD_PATH

# Check if the download was successful
if [ $? -eq 0 ]; then
    echo "✅ Blob '$BLOB_NAME' downloaded successfully to '$DOWNLOAD_PATH'."
else
    echo "❌ Failed to download blob."
    exit 1
fi
