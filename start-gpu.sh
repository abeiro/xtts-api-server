#!/bin/bash

BASE_DIR="/home/dwemer"
REPO_URL="https://github.com/Dwemer-Dynamics/chatterbox"
REPO_DIR="$BASE_DIR/chatterbox"
VENV_DIR="$REPO_DIR/venv"

cd "$REPO_DIR"

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv venv
else
    echo "Virtual environment already exists."
fi

# Activate virtual environment
source venv/bin/activate
# Launch the service
python3 restapi.py
