#!/bin/bash

# Pre-commit setup script for Emerald Grove Veterinary Clinic
# This script installs and configures pre-commit hooks

set -e

echo "🚀 Setting up pre-commit hooks for Emerald Grove Veterinary Clinic..."

# Check if pre-commit is installed
if ! command -v pre-commit &> /dev/null; then
    echo "📦 Installing pre-commit..."
    if ! command -v pip &> /dev/null; then
        echo "❌ pip is not installed. Please install pip first."
        exit 1
    fi
    pip install --user pre-commit
else
    echo "✅ pre-commit is already installed"
fi

# Check if Maven wrapper exists
if [ ! -f "./mvnw" ]; then
    echo "❌ Maven wrapper (mvnw) not found. Please ensure you're in the project root."
    exit 1
fi

# Install pre-commit hooks
echo "🔧 Installing pre-commit hooks..."
pre-commit install

# Install pre-commit commit-msg hook
echo "📝 Installing commit-msg hook..."
pre-commit install --hook-type commit-msg

# Install pre-push hook
echo "🚀 Installing pre-push hook..."
pre-commit install --hook-type pre-push

# Run pre-commit on all files to ensure everything is clean
echo "🧹 Running pre-commit on all files..."
pre-commit run --all-files || {
    echo "⚠️  Some pre-commit hooks failed. Please fix the issues above."
    echo "💡 You can run 'pre-commit run --all-files' again after fixing issues."
    exit 1
}

echo "✅ Pre-commit setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "   1. Make changes to your code"
echo "   2. Stage your changes: git add ."
echo "   3. Commit: git commit -m 'your commit message'"
echo "   4. Pre-commit hooks will run automatically"
echo ""
echo "🔍 To run hooks manually:"
echo "   pre-commit run --all-files"
echo ""
echo "🔄 To update hooks:"
echo "   pre-commit autoupdate"
echo "   pre-commit run --all-files"
