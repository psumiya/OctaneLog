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
echo "🔍 3. Verifying GEMINI 3.0 Availability..."

# Test 3.0 Flash
curl -s -H 'Content-Type: application/json' \
    -d '{"contents":[{"parts":[{"text":"Hello from Gemini 3.0 check."}]}]}' \
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.0-flash:generateContent?key=${API_KEY}" > flash3_response.json

if grep -q "error" flash3_response.json; then
    echo "⚠️  gemini-3.0-flash NOT AVAILABLE yet."
    echo "   (This is expected if the model is not yet public/whitelisted)."
else
    echo "🚀 SUCCESS: gemini-3.0-flash is LIVE and accepting requests!"
fi

# Test 3.0 Pro
curl -s -H 'Content-Type: application/json' \
    -d '{"contents":[{"parts":[{"text":"Reasoning check."}]}]}' \
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.0-pro:generateContent?key=${API_KEY}" > pro3_response.json

if grep -q "error" pro3_response.json; then
    echo "⚠️  gemini-3.0-pro NOT AVAILABLE yet."
else
    echo "🚀 SUCCESS: gemini-3.0-pro is LIVE!"
fi

echo "----------------------------------------------------------------"
echo "Cleaning up..."
rm models.json text_response.json flash3_response.json pro3_response.json
echo "Done."
