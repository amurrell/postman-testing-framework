#!/usr/bin/env bash

set -e

ORIGINAL_DIR=$(pwd)

# print the ASCII chars above
printf "========== 🤖 Welcome to the postman-testing-framework init script\n"

# Use a here document to print the text
cat <<'EOF'
 ______ ______  ______  ______ __    __  ______  __   __       ______ ______  ______  ______ __  __   __  ______      
/\  == /\  __ \/\  ___\/\__  _/\ "-./  \/\  __ \/\ "-.\ \     /\__  _/\  ___\/\  ___\/\__  _/\ \/\ "-.\ \/\  ___\     
\ \  _-\ \ \/\ \ \___  \/_/\ \\ \ \-./\ \ \  __ \ \ \-.  \    \/_/\ \\ \  __\\ \___  \/_/\ \\ \ \ \ \-.  \ \ \__ \    
 \ \_\  \ \_____\/\_____\ \ \_\\ \_\ \ \_\ \_\ \_\ \_\\"\_\      \ \_\\ \_____\/\_____\ \ \_\\ \_\ \_\\"\_\ \_____\   
  \/_/   \/_____/\/_____/  \/_/ \/_/  \/_/\/_/\/_/ \/_/ \/_/       \/_/ \/_____/\/_____/  \/_/ \/_/\/_/ \/_/\/_____/   
 ______ ______  ______  __    __  ______  __     __  ______  ______  __  __                                           
/\  ___/\  == \/\  __ \/\ "-./  \/\  ___\/\ \  _ \ \/\  __ \/\  == \/\ \/ /                                           
\ \  __\ \  __<\ \  __ \ \ \-./\ \ \  __\\ \ \/ ".\ \ \ \/\ \ \  __<\ \  _"-.                                         
 \ \_\  \ \_\ \_\ \_\ \_\ \_\ \ \_\ \_____\ \__/".~\_\ \_____\ \_\ \_\ \_\ \_\                                        
  \/_/   \/_/ /_/\/_/\/_/\/_/  \/_/\/_____/\/_/   \/_/\/_____/\/_/ /_/\/_/\/_/                                        
EOF
printf "\n\n"

# Step 1: Check if we are running from a testing folder - pwd and check end for testing
if [[ $(pwd) != *"testing"* ]]; then
    printf "========== 👉 Please run this script from the testing folder.\n"
    exit 1
fi

# Step 2: Prompt the user for the name of their test collection
printf "========== 💬 Choose a name for your test-collection\n\nWe recommend <platform-folder>-<fork> eg. myapp-angela\n\n"
read -p "Enter the name of your test collection (following the pattern [a-z-0-9]):" name

# Validate the name against the pattern [a-z-0-9]
if ! [[ $name =~ ^[a-z0-9-]+$ ]]; then
    printf "========== 👉 The name should follow the pattern [a-z-0-9].\n"
    exit 1
fi

# Check if the config/<name>.configuration.json file exists
if [ -f "config/${name}.configuration.json" ]; then
    printf "========== ✅ config/${name}.configuration.json already exists. Skipping this...\n"
else
    # Create the configuration file
    cp template.configuration.json "config/${name}.configuration.json"

    # Step 3: Replace variables in config/<name>.configuration.json
    template_vars=($(grep -o ': "[A-Z_]\+"' template.configuration.json | sed 's/"//' | sed 's/://;s/"$//'))

    # if template_vars is empty, exit 1
    if [ -z "$template_vars" ]; then
        printf "========== 👉 No template variables found in template.configuration.json\n"
        exit 1
    fi

    # dump the template vars for debugging
    printf "========== 📄 Found these template variables:\n"
    printf '%s\n' "${template_vars[@]}"
    printf "\n\n"

    for var in "${template_vars[@]}"; do

        # if var is POSTMAN_API_KEY, then print some info about it 
        # - Create/Retrieve a Postman API key - to create, click your avatar in postman → settings → API Keys. 
        if [ "$var" = "POSTMAN_API_KEY" ]; then
            printf "========== 💬 The POSTMAN_API_KEY variable value relates to your Postman API key.\n\n"
            printf "Create/Retrieve a Postman API key - to create, click your avatar in postman → settings → API Keys.\n\n"
        fi

        # if var is COLLECTION_UID, then print some info about it
        if [ "$var" = "COLLECTION_UID" ]; then
            printf "========== 💬 The COLLECTION_UID variable value relates to the collection UID.\n\n"
            printf "You can find the collection UID by clicking the collection in the left side\n\n"
            printf "navigation pane, and then using the right side navigation pane to select \"info\" icon.\n\n"
        fi

        # if var is FOLDER_NAME, then print some info about it 
        if [ "$var" = "FOLDER_NAME" ]; then
            printf "========== 💬 The FOLDER_NAME variable value relates to the top-level folder name in your collection.\n\n"
            printf "It is recommended to make it an app/platform or service or something recognizeable.\n\n"
            printf "And to make it match the pattern [a-z-0-9].\n\n"
            printf "If you have two folders with the same name, postman behaves weirdly.\n\n"
        fi

        # if var is ENVIRONMENT, then we will print some info
        if [ "$var" = "ENVIRONMENT" ]; then
            printf "========== 💬 The ENVIRONMENT variable value relates to <environment-name>.postman_environment.json\n\n"
            printf "When you export your environment from postman, it will save like that.\n\n "
            printf "Recommend renaming the downloaded file sure to name it something [a-zA-z0-9_-].\n\n" 
            printf "eg. myapp-prod.postman_environment.json\n\n"
            printf "Be sure to save it to environments/ folder.\n\n"
        fi

        read -p "Enter the value for \"$var\": " value
        printf "\n\n"
        sed -i '' "s/: \"$var\"/: \"$value\"/g" "config/${name}.configuration.json"
    done
fi

# Cat the file to show the user the result
printf "========== 📄 Here is the outputted config/${name}.configuration.json file:\n"
cat "config/${name}.configuration.json"

# Step 4: Generate automations.json
# Initialize the automations JSON structure
automations_json="{\"automations\": []}"

# Loop through config files
for config_file in config/*.configuration.json; do
    # Extract the <name> from the file name
    name=$(basename "$config_file" .configuration.json)
    
    # Create an entry for this <name>
    automation_entry="{\"name\": \"$name\", \"cmd\": \"./run-tests -c $name\"}"
    
    # Append the entry to automations_json
    automations_json=$(echo "$automations_json" | node -e "const fs = require('fs');
        const data = JSON.parse(fs.readFileSync(0, 'utf-8'));
        data.automations.push($automation_entry);
        console.log(JSON.stringify(data, null, 4));" <(echo "$automations_json"))
done

# Write the automations JSON to automations.json
echo "$automations_json" > automations.json

# cat the file
printf "========== 📄 Here is the outputted automations.json file:\n"
cat automations.json

# Step 5: Check if .git/hooks folder exists and copy the script if requested
if [ -d "../.git/hooks" ]; then
    read -p "Do you want to copy the run-automations script (scripts/git-hook) to ../.git/hooks? (yes/no): " copy_to_hooks
    if [ "$copy_to_hooks" = "yes" ]; then
        script_name="git-hook"
        read -p "Enter the hook name (eg., pre-commit, pre-push): " hook_name
        echo
        read -p "Enter the script name (default is "git-hook" inside of scripts/git-hook): " script_name
        cp "scripts/$script_name" "../.git/hooks/$hook_name"
        printf "Script '$script_name' copied to ../.git/hooks/$hook_name\n"
    fi
else
    printf "========== 🙈 The .git/hooks folder does not exist. It needs to be version-controlled to utilize git hooks.\n"
fi

printf "=========== ✅ Script completed successfully.\n"