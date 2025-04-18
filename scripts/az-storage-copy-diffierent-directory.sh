#!/bin/bash

# Variables
SOURCE_STORAGE_ACCOUNT="mahfilstorageprod"
SOURCE_SAS_TOKEN="sv=2024-11-04&ss=bfqt&srt=sco&sp=rwdlacupiytfx&se=2025-03-20T02:32:11Z&st=2025-03-19T18:32:11Z&spr=https&sig=lk5YyqD2siPNjI6zn5VUmh%2FxK1Sr2CXsNNArm3jBwoo%3D"

DEST_STORAGE_ACCOUNT="mahfilstorageprd"
DEST_SAS_TOKEN="sv=2024-11-04&ss=bfqt&srt=sco&sp=rwdlacupiytfx&se=2025-03-20T02:33:39Z&st=2025-03-19T18:33:39Z&spr=https&sig=o0nOtQ34LXSg8NQKk4q%2BWM%2Bv95rX4C0gdX9%2Fx00GL2Y%3D"

# Function to create a container in the destination account
create_container() {
    local container_name=$1
    echo "Creating container '$container_name' in destination account..."
    az storage container create \
        --name "$container_name" \
        --account-name "$DEST_STORAGE_ACCOUNT" \
        --sas-token "$DEST_SAS_TOKEN" \
        --output none
}

# Function to copy blobs from source to destination
copy_blobs() {
    local container_name=$1
    echo "Copying blobs from container '$container_name'..."
    azcopy copy \
        "https://${SOURCE_STORAGE_ACCOUNT}.blob.core.windows.net/${container_name}?${SOURCE_SAS_TOKEN}" \
        "https://${DEST_STORAGE_ACCOUNT}.blob.core.windows.net/${container_name}?${DEST_SAS_TOKEN}" \
        --recursive=true
}

# Get list of containers in the source account
echo "Fetching containers from source account..."
containers=$(az storage container list \
    --account-name "$SOURCE_STORAGE_ACCOUNT" \
    --sas-token "$SOURCE_SAS_TOKEN" \
    --query "[].name" \
    --output tsv)

# Check if any containers were found
if [ -z "$containers" ]; then
    echo "No containers found in the source account."
    exit 1
fi

# Loop through each container
for container in $containers; do
    echo "Processing container: $container"

    # Create the container in the destination account
    create_container "$container"

    # Copy all blobs from the source container to the destination container
    copy_blobs "$container"
done

echo "All containers and blobs copied successfully!"