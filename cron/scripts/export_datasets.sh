#!/bin/bash

export OUTPUT_DIR=/var/www/html/download

source /etc/environment

python ./export_datasets.py

