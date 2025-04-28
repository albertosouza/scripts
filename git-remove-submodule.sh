#!/bin/bash

# Usage: ./git-remove-submodule.sh <submodule-name>
#
# Description:
#   This script safely removes a git submodule from your repository.
#   It will:
#   1. Verify the submodule exists in .gitmodules
#   2. Extract the submodule path
#   3. Remove the submodule completely
#
# Arguments:
#   <submodule-name>: Name of the submodule as defined in .gitmodules
#
# Example:
#   ./git-remove-submodule.sh my-submodule
#
# Note: Must be run from the root of the git repository

# Check if submodule name is provided
if [ -z "$1" ]; then
    echo "Error: Submodule name is required"
    echo "Usage: $0 <submodule-name>"
    exit 1
fi

submodulename="$1"

# Check if .gitmodules file exists
if [ ! -f ".gitmodules" ]; then
    echo "Error: .gitmodules file not found in current directory"
    exit 1
fi

# Extract submodule path from .gitmodules file
submodulepath=$(git config -f .gitmodules --get "submodule.$submodulename.path")

if [ -z "$submodulepath" ]; then
    echo "Error: Submodule '$submodulename' not found in .gitmodules"
    exit 1
fi

echo "Removing submodule: $submodulename"
echo "Submodule path: $submodulepath"

# Remove the submodule
git submodule deinit -f "$submodulepath"
# Commit the deinit changes
git add .gitmodules
git commit -m "deinit submodule: $submodulename"
git rm -f "$submodulepath"
rm -rf ".git/modules/$submodulepath"

echo "Submodule '$submodulename' has been successfully removed"