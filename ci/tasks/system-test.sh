#!/bin/bash

set -eu

deployment="system-test-$RANDOM"

mv $BINARY_PATH ./cup
chmod +x ./cup

# DEPLOY WITH AUTOGENERATED CERT, NO DOMAIN

./cup deploy $deployment

config=$(./cup info --json $deployment)
domain=$(echo $config | jq -r '.config.domain')
username=$(echo $config | jq -r '.config.concourse_username')
password=$(echo $config | jq -r '.config.concourse_password')
echo $config | jq -r '.config.concourse_ca_cert' > generated-ca-cert.pem

fly --target system-test login \
  --ca-cert generated-ca-cert.pem \
  --concourse-url https://$domain \
  --username $username \
  --password $password

set -x
fly --target system-test sync
fly --target system-test workers --details
set +x

# DEPLOY WITH AUTOGENERATED CERT, AND CUSTOM DOMAIN

custom_domain="$deployment-auto-2.concourse-up.engineerbetter.com"

./cup deploy $deployment \
  --domain $custom_domain \
  --workers 2 \
  --worker-size medium
  --region us-east-1

sleep 60

config=$(./cup info --json $deployment)
username=$(echo $config | jq -r '.config.concourse_username')
password=$(echo $config | jq -r '.config.concourse_password')
echo $config | jq -r '.config.concourse_ca_cert' > generated-ca-cert.pem

fly --target system-test-custom-domain login \
  --ca-cert generated-ca-cert.pem \
  --concourse-url https://$custom_domain \
  --username $username \
  --password $password

set -x
fly --target system-test-custom-domain sync
fly --target system-test-custom-domain workers --details
set +x

# DEPLOY WITH USER PROVIDED CERT

custom_domain="$deployment-user.concourse-up.engineerbetter.com"

certstrap init \
  --common-name "$deployment" \
  --passphrase "" \
  --organization "" \
  --organizational-unit "" \
  --country "" \
  --province "" \
  --locality ""

certstrap request-cert \
   --passphrase "" \
   --domain $custom_domain

certstrap sign "$custom_domain" --CA "$deployment"

./cup deploy $deployment \
  --domain $custom_domain \
  --tls-cert "$(cat out/$custom_domain.crt)" \
  --tls-key "$(cat out/$custom_domain.key)" \
  --workers 1 \
  --worker-size large

sleep 60

config=$(./cup info --json $deployment)
username=$(echo $config | jq -r '.config.concourse_username')
password=$(echo $config | jq -r '.config.concourse_password')
echo $config | jq -r '.config.concourse_ca_cert' > generated-ca-cert.pem

fly --target system-test-custom-domain-with-cert login \
  --ca-cert out/$deployment.crt \
  --concourse-url https://$custom_domain \
  --username $username \
  --password $password

set -x
fly --target system-test-custom-domain-with-cert sync
fly --target system-test-custom-domain-with-cert workers --details
set +x

# DESTROY

./cup --non-interactive destroy $deployment