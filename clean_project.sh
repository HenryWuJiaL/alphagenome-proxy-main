#!/bin/bash

# Script to clean project files by removing emojis and translating Chinese to English

echo "Cleaning project files..."

# List of files to process
FILES=(
    "API_REFERENCE.md"
    "CLOUD_DEPLOYMENT_GUIDE.md"
    "CLOUD_DEPLOYMENT_QUICK.md"
    "DEPLOYMENT_GUIDE.md"
    "MULTI_PLATFORM_DEPLOYMENT_SUMMARY.md"
    "TESTING_GUIDE.md"
    "API_KEY_INTEGRATION_SUMMARY.md"
    "CLIENT_DEPLOYMENT_GUIDE.md"
    "CLIENT_INFO_TEMPLATE.md"
    "GITHUB_PROJECT_STRUCTURE.md"
    "DEPLOYMENT_CHECKLIST.md"
    "OFFICIAL_VS_PROXY_COMPARISON.md"
)

# Process each file
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "Processing $file..."
        
        # Remove emojis and translate Chinese to English
        # This is a simplified approach - you may need to manually review some files
        
        # Remove common emoji patterns
        sed -i '' 's/[🎓🚀📖🔧📡🐳☁️🧪🔍🛠️📚🔒💰🤝📄🙏🎉✅❌🔄📦🔐🐳📤🚀🌐✅🎉🌐🔗📊🌍🧪📚💰🎓💡]/g' "$file"
        
        # Remove emoji sequences
        sed -i '' 's/[[:space:]]*[🎓🚀📖🔧📡🐳☁️🧪🔍🛠️📚🔒💰🤝📄🙏🎉✅❌🔄📦🔐🐳📤🚀🌐✅🎉🌐🔗📊🌍🧪📚💰🎓💡][[:space:]]*/ /g' "$file"
        
        echo "Processed $file"
    else
        echo "File $file not found, skipping..."
    fi
done

echo "Project cleaning complete!"
echo ""
echo "Note: This script provides basic emoji removal."
echo "For complete Chinese to English translation, please manually review the files."
echo "Key files that may need manual attention:"
echo "- README files"
echo "- Documentation files"
echo "- Configuration files"
