raw=$(az rest -m POST -u $resource_id/getResourceUploadUrl?api-version=2022-12-01)

upload_url=$(echo $raw | jq -r .uploadUrl)
relative_path=$(echo $raw | jq -r .relativePath)

# Download binary
echo "Downloading binary from $source_url"
curl "$source_url" -o localfile

# Upload to remote
echo "Upload $source_url to $relative_path" through $upload_url

az storage file upload --file-url "$upload_url"  --source localfile

echo "upload finished"

echo {\"relativePath\": \"$relative_path\"} > $AZ_SCRIPTS_OUTPUT_PATH