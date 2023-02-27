#!/bin/sh
ansible-playbook packages.yaml --connection local "$@"
