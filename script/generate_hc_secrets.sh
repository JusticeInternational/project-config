#!/bin/bash

set -e

source ./script/env_source.sh

# setup secrets for hc app

# JSON Web Token
# set automatically
# JWT_SECRET

# signup required key phrase
# set automatically
# PRIVATE_KEY_PASSPHRASE


# required geo location api token https://api.mapbox.com/geocoding
# not auto generated, need to prompt comment
# MAPBOX_TOKEN:


# Not required used in mongo DB legacy exports but we'll set it
# set from defaults
# MONGODB_PASSWORD

# required for email messages, should be set manually
# SMTP_USERNAME: "cmVkc29sLmludGVybmF0aW9uYWxAZ21haWwuY29tCg=="
# SMTP_PASSWORD: "SnVzdGljaWE1Lgo="

# Should be set automatically
#  NEO4J_USERNAME: "YWRtaW4K"
#  NEO4J_PASSWORD: "YWRtaW4xMjNwYXNzCg=="