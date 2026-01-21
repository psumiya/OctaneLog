#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: ./debug_gemini.sh YOUR_API_KEY"
    exit 1
fi

API_KEY=$1

echo "----------------------------------------------------------------"
echo "🔍 1. Listing Available Models (v1beta)..."
curl -s "https://generativelanguage.googleapis.com/v1beta/models?key=${API_KEY}" > models.json

if grep -q "error" models.json; then
    echo "❌ ListModels Failed:"
    cat models.json
    rm models.json
    exit 1
else
    echo "✅ Success. Found the following VISION models:"
    # Filter for models that likely support vision (flash, pro, pro-vision)
    grep -o '"name": "models/[^"]*"' models.json | grep -E "flash|pro|vision"
fi

echo "----------------------------------------------------------------"
echo "🔍 2. Testing Simple Text Generation (gemini-1.5-flash)..."

curl -s -H 'Content-Type: application/json' \
    -d '{"contents":[{"parts":[{"text":"Hello, reliable world!"}]}]}' \
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${API_KEY}" > text_response.json

if grep -q "error" text_response.json; then
    echo "❌ Text Gen Failed for gemini-1.5-flash. Trying gemini-pro..."
    
    curl -s -H 'Content-Type: application/json' \
        -d '{"contents":[{"parts":[{"text":"Hello, reliable world!"}]}]}' \
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${API_KEY}" > text_response.json
        
    if grep -q "error" text_response.json; then
        echo "❌ Text Gen Failed for gemini-pro too."
        cat text_response.json
    else
        echo "✅ gemini-pro Text works!"
    fi
else
    echo "✅ gemini-1.5-flash Text works!"
fi

echo "----------------------------------------------------------------"
echo "Cleaning up..."
rm models.json text_response.json
echo "Done."
