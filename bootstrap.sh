#!/bin/bash
PROJECT_DIR="$(dirname "${BASH_SOURCE[0]}")"
VENV_DIR="${PROJECT_DIR}/.venv"

if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
    "$VENV_DIR"/bin/pip install -r "$PROJECT_DIR"/requirements.txt
fi

source "$VENV_DIR"/bin/activate
ansible-galaxy collection install ansible.utils community.general
