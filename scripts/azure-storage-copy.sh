#!/bin/bash

# Exit on error
set -e

# Source and destination details
SOURCE_STORAGE_ACCOUNT="kahfadsstaging"
TARGET_STORAGE_ACCOUNT="kahfadsproduction"
SOURCE_RESOURCE_GROUP="kahfads-staging"
TARGET_RESOURCE_GROUP="kahfads-production"

# Login to Azure if needed
az login --output none

# Fetch all containers from the source storage account
CONTAINERS=$(az storage container list --account-name "$SOURCE_STORAGE_ACCOUNT" --query "[].name" -o tsv)

# Ensure at least one container exists
if [ -z "$CONTAINERS" ]; then
    echo "No containers found in source storage account!"
    exit 1
fi

# Count number of containers and set PARALLEL_JOBS accordingly
PARALLEL_JOBS=$(echo "$CONTAINERS" | wc -l)
PARALLEL_JOBS=$((PARALLEL_JOBS > 0 ? PARALLEL_JOBS : 1))  # Ensure at least 1 job

echo "Found $PARALLEL_JOBS containers in $SOURCE_STORAGE_ACCOUNT."
echo "Starting parallel copy of blobs..."

# Get Storage Account Keys (if needed)
SOURCE_KEY=$(az storage account keys list --account-name "$SOURCE_STORAGE_ACCOUNT" --resource-group "$SOURCE_RESOURCE_GROUP" --query "[0].value" -o tsv)
TARGET_KEY=$(az storage account keys list --account-name "$TARGET_STORAGE_ACCOUNT" --resource-group "$TARGET_RESOURCE_GROUP" --query "[0].value" -o tsv)

# Function to copy blobs for a single container
copy_blobs() {
    local container="$1"

    echo "Fetching blobs from container: $container"

    # List all blobs in the source container
    BLOBS=$(az storage blob list --account-name "$SOURCE_STORAGE_ACCOUNT" --account-key "$SOURCE_KEY" --container-name "$container" --query "[].name" -o tsv)

    if [ -z "$BLOBS" ]; then
        echo "No blobs found in $container, skipping..."
        return
    fi

    for blob in $BLOBS; do
        echo "Copying $container/$blob to $TARGET_STORAGE_ACCOUNT..."
        az storage blob copy start \
            --destination-blob "$blob" \
            --destination-container "$container" \
            --account-name "$TARGET_STORAGE_ACCOUNT" \
            --account-key "$TARGET_KEY" \
            --source-uri "https://$SOURCE_STORAGE_ACCOUNT.blob.core.windows.net/$container/$blob" &  # Run in background
    done
}

# Export function and vars for parallel execution
export -f copy_blobs
export SOURCE_STORAGE_ACCOUNT TARGET_STORAGE_ACCOUNT SOURCE_KEY TARGET_KEY

# Run copy process in parallel
echo "$CONTAINERS" | xargs -n1 -P$PARALLEL_JOBS bash -c 'copy_blobs "$@"' _

echo "All blobs copied successfully!"
