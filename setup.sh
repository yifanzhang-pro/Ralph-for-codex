#!/bin/bash

# Cralph Project Setup Script - Global Version
set -e

PROJECT_NAME=${1:-"my-project"}
CRALPH_HOME="$HOME/.cralph"

echo "🚀 Setting up Cralph project: $PROJECT_NAME"

# Create project directory in current location
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Create structure
mkdir -p {specs/stdlib,src,examples,logs,docs/generated}

# Copy templates from Cralph home
cp "$CRALPH_HOME/templates/PROMPT.md" .
cp "$CRALPH_HOME/templates/fix_plan.md" @fix_plan.md
cp "$CRALPH_HOME/templates/AGENT.md" @AGENT.md
cp -r "$CRALPH_HOME/templates/specs/"* specs/ 2>/dev/null || true

# Initialize git
git init
echo "# $PROJECT_NAME" > README.md
git add .
git commit -m "Initial Cralph project setup"

echo "✅ Project $PROJECT_NAME created!"
echo "Next steps:"
echo "  1. Edit PROMPT.md with your project requirements"
echo "  2. Update specs/ with your project specifications"  
echo "  3. Run: cralph --monitor"
echo "  4. Monitor: cralph-monitor (if running manually)"
