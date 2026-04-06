#!/bin/bash

echo "🚀 Starting Hello Service Deployment UI..."
echo "Make sure Minikube, Docker, Helm, and kubectl are installed."
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js first:"
    echo "curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt-get install -y nodejs"
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install Node.js first."
    exit 1
fi

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

echo "🌐 Starting web server at http://localhost:3000"
echo "Open your browser and follow the deployment steps."
echo "Press Ctrl+C to stop the server."
echo ""

npm start