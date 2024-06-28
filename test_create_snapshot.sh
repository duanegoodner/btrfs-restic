#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
  source .env
else
  echo ".env file not found!"
  exit 1
fi

source create_snapshot.sh

create_snapshot /var/tmp var_tmp_new