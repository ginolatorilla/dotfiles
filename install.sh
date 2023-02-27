#!/bin/sh
ansible-playbook dotfiles.yaml --connection local "$@"
