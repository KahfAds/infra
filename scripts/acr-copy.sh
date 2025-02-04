#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Required variables
SOURCE_ACR="kahfadsstaging"
TARGET_ACR="kahfadsproduction"
RESOURCE_GROUP="kahfads-production"

# Login to Azure if needed
az login --output none

# Get all repositories from the source ACR
REPOS=$(az acr repository list --name $SOURCE_ACR --output tsv)

# Count number of repositories and set PARALLEL_JOBS accordingly
PARALLEL_JOBS=$(echo "$REPOS" | wc -l)
PARALLEL_JOBS=$((PARALLEL_JOBS > 0 ? PARALLEL_JOBS : 1))  # Ensure at least 1 job

echo "Found $PARALLEL_JOBS repositories in $SOURCE_ACR."
echo "Starting parallel copy of images..."

# Function to copy images for a single repository
copy_images() {
    local repo="$1"
    echo "Fetching tags for repository: $repo"

    # Get all tags for the repository
    TAGS=$(az acr repository show-tags --name $SOURCE_ACR --repository "$repo" --output tsv)

    if [ -z "$TAGS" ]; then
        echo "No tags found for $repo, skipping..."
        return
    fi

    for tag in $TAGS; do
        echo "Copying $repo:$tag to $TARGET_ACR..."
        az acr import --name $TARGET_ACR \
            --source "$SOURCE_ACR.azurecr.io/$repo:$tag" \
            --resource-group "$RESOURCE_GROUP" \
            --force &  # Run in background
    done
}

# Export function so it works in parallel execution
export -f copy_images
export SOURCE_ACR TARGET_ACR RESOURCE_GROUP

# Run copy process in parallel
echo "$REPOS" | xargs -n1 -P$PARALLEL_JOBS bash -c 'copy_images "$@"' _

echo "All images copied successfully!"

