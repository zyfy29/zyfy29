# postprocess.sh - README.md post-processing script
# This script performs URL replacement and removes empty sections

README_FILE="README.md"
CHANGES_MADE=false

echo "Starting README.md post-processing..."

# Check if README.md exists
if [[ ! -f "$README_FILE" ]]; then
    echo "Error: README.md not found"
    exit 1
fi

# Create backup
cp "$README_FILE" "${README_FILE}.backup"

# 1. Replace LeetCode URLs from .com to .cn
echo "Checking for LeetCode.com URLs..."
if grep -q "www\.leetcode\.com" "$README_FILE"; then
    echo "Found LeetCode.com URLs, updating to .cn domain..."

    # Replace www.leetcode.com with www.leetcode.cn in href attributes
    sed -i '' 's/href="https:\/\/www\.leetcode\.com/href="https:\/\/www\.leetcode\.cn/g' "$README_FILE"
    sed -i '' 's/href="http:\/\/www\.leetcode\.com/href="https:\/\/www\.leetcode\.cn/g' "$README_FILE"

    CHANGES_MADE=true
    echo "✅ LeetCode URLs updated"
else
    echo "No LeetCode.com URLs found"
fi

# 2. Check and clean empty Connect with me section
echo "Checking Connect with me section..."
if grep -q '<h3 align="left">Connect with me:</h3>' "$README_FILE"; then
    echo "Found Connect with me section, checking for links..."

    # Extract the content between Connect with me h3 and the next h3 tag
    awk '/<h3 align="left">Connect with me:<\/h3>/{flag=1; next}
         /<h3 align="left">/{if(flag) exit}
         flag{content=content $0 "\n"}
         END{print content}' "$README_FILE" > connect_section.tmp

    # Check if the extracted section contains any href links
    if ! grep -q 'href=' connect_section.tmp; then
        echo "No links found in Connect with me section, removing it..."

        # Remove the Connect with me section (h3 + p tags until next h3)
        awk '
            /<h3 align="left">Connect with me:<\/h3>/{skip=1; next}
            /<h3 align="left">/{if(skip) {skip=0; print; next}}
            !skip{print}
        ' "$README_FILE" > README_temp.md

        mv README_temp.md "$README_FILE"
        CHANGES_MADE=true
        echo "✅ Empty Connect with me section removed"
    else
        echo "Links found in Connect with me section, keeping it"
    fi

    # Clean up temp file
    rm -f connect_section.tmp
else
    echo "No Connect with me section found"
fi

# Show changes if any were made
if [[ "$CHANGES_MADE" == "true" ]]; then
    echo ""
    echo "Changes made to README.md:"
    diff "${README_FILE}.backup" "$README_FILE" || true
    echo ""
    echo "✅ Post-processing completed with changes"
else
    echo "ℹ️ No changes needed"
fi

# Clean up backup
rm -f "${README_FILE}.backup"

# Exit with appropriate code
if [[ "$CHANGES_MADE" == "true" ]]; then
    exit 0  # Changes made
else
    exit 1  # No changes made
fi
