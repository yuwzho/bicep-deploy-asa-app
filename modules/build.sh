# Initialize result with an empty string
result=""

# Start the while loop
while true; do
    # Run the command and store the result
    result=$(az resource show --ids $resource_id --query properties.provisioningState -o tsv)

    # Check if the result is 'Failed' or 'Succeeded'
    if [[ "$result" == "Failed" ]] || [[ "$result" == "Succeeded" ]]; then
        # If so, exit the loop
        break
    fi

    # Optional: sleep for a while before the next iteration
    sleep 5
done

# Print the final result
echo "Final Result: $result"