#!/bin/bash

#+--------------------------------------------------------------------------------+
#|                                                                                |
#|   setup-venv.sh                                                                |
#|                                                                                |
#+--------------------------------------------------------------------------------+
#|   Guillaume Plante <codegp@icloud.com>                                         |
#|   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      |
#+--------------------------------------------------------------------------------+

WHITE='\033[0;30m'
MAGENTA='\033[0;35m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'

# Determine the ROOT_DIRECTORY based on the script's location
SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIRECTORY=$(realpath "$SCRIPT_DIR/..")

ENV_FILE="$ROOT_DIRECTORY/.env"

# Define the virtual environment path
VENV_PATH="$ROOT_DIRECTORY/venv"
ACTIVATE_FILE="$VENV_PATH/bin/activate"

# Define the log file
LOG_FILE="$ROOT_DIRECTORY/logs/install-venv.log"


mkdir -p "$ROOT_DIRECTORY/logs"

log_info() {
    echo "[$(date)] $1" >> "$LOG_FILE"
    echo -e "${RED}[install]${NC} ${YELLOW}$1${NC}"
}


# Function to setup Python virtual environment
setup_virtualenv() {
    # Check Python version
    PYTHON_VERSION=$(python3 --version 2>&1)
    if [[ $? -ne 0 ]]; then
        log_error "Python3 is not installed. Please install Python3 first."
        return 1
    fi

    log_info "Found $PYTHON_VERSION"

    # Create virtual environment
    if [[ -d "venv" ]]; then
        log_info "Virtual environment already exists in 'venv'."
    else
        log_info "Creating virtual environment in 'venv'..."
        python3 -m venv venv
        if [[ $? -ne 0 ]]; then
            log_error "Failed to create virtual environment."
            return 1
        fi
    fi

    # Activate virtual environment
    source "$ACTIVATE_FILE"
    if [[ $? -ne 0 ]]; then
        log_error "Failed to activate virtual environment."
        return 1
    fi

    log_info "Virtual environment activated."

    # Install dependencies
    if [[ -f "requirements.txt" ]]; then
        log_info "Installing dependencies from requirements.txt..."
        pip install -r requirements.txt
        if [[ $? -ne 0 ]]; then
            log_error "Failed to install dependencies."
            deactivate
            return 1
        fi
        log_info "Dependencies installed successfully."
    else
        log_info "No requirements.txt file found. Skipping dependency installation."
    fi

    deactivate
    log_info "Virtual environment setup completed."
    return 0
}

setup_virtualenv
