#!/usr/bin/env bash

set -euo pipefail

mkdir -p ~/.aws

cat > ~/.aws/credentials <<EOF
[default]
aws_access_key_id = ${ACCESS_KEY_ID}
aws_secret_access_key = ${SECRET_ACCESS_KEY}
EOF

cat > ~/.aws/config <<EOF
[default]
region = eu-central-1
output = json

[profile testing]
role_arn = ${ROLE_ARN}
source_profile = default
region = eu-central-1
EOF
