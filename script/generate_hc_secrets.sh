#!/bin/bash

set -e

source ./script/env_source.sh
source ./script/az_helpers.sh

# setup secrets for hc app
function random_CAP_letter() {
  n=1
  r=$(($(($(uuidgen | awk -F'-' '{print $1}' | sed 's/[^1-9]*//g') * $RANDOM)) % 27))
  [[ $r -eq 0 ]] && r=1

  for i in {a..z}; do
    [[ $r -eq $n ]] && echo $i | tr '[:lower:]' '[:upper:]' && break
    n=$(($n+1))
  done
}

function get_char() {
    IN_SR="$(echo $1 | sed 's/[^1-9]*//g')"
    if [ -z "${IN_SR}" ]; then
      r=$(( $RANDOM % 18))
    else
      r=$(( $(echo "${IN_SR}" ) % 18))
    fi
    i=0
    for c in $(echo '\! \@ \# \$ \% \^ \& \- \_ \% \^ \& \_ \- \$ \# \@ \!') ; do
        [[ $i -eq $r ]] && eval echo "${c}" && break
        i=$(( $i + 1 ))
    done
}

function generate_secret() {
  _max_pass="${1:-64}"
  _pass_gen="${2}"

  part1=$(uuidgen | tr '[:upper:]' '[:lower:]'|awk -F'-' '{print $2$3}')
  part2=$(uuidgen | tr '[:upper:]' '[:lower:]'|awk -F'-' '{print $1$4}')
  part3=$(uuidgen | tr '[:upper:]' '[:lower:]'|awk -F'-' '{print $3$4}')
  part4=$(uuidgen | tr '[:upper:]' '[:lower:]'|awk -F'-' '{print $5$3}')
  pass_gen=''
  for i in {0..6}; do
     [[ 0 -eq $(( $RANDOM % 7 )) ]] && pass_gen="${pass_gen}$(get_char "${part1}")${part1}"
     [[ 1 -eq $(( $RANDOM % 7 )) ]] && pass_gen="${pass_gen}$(get_char "${part2}")${part2}"
     [[ 2 -eq $(( $RANDOM % 7 )) ]] && pass_gen="${pass_gen}$(get_char "${part1}")$(random_CAP_letter)"
     [[ 3 -eq $(( $RANDOM % 7 )) ]] && pass_gen="${pass_gen}$(get_char "${part3}")${part3}"
     [[ 4 -eq $(( $RANDOM % 7 )) ]] && pass_gen="${pass_gen}$(get_char "${part4}")${part4}"
     [[ 5 -eq $(( $RANDOM % 7 )) ]] && pass_gen="${pass_gen}$(get_char "${part2}")$(random_CAP_letter)"
     [[ 6 -eq $(( $RANDOM % 7 )) ]] && pass_gen="${pass_gen}$(get_char "${part3}")$(random_CAP_letter)"
  done

  _pass_gen="${_pass_gen}${pass_gen}"
  while [[ $(echo "${_pass_gen}" | wc -c|sed -r 's/( )+//g') -le ${_max_pass} ]]; do
      _pass_gen=$(generate_secret "${_max_pass}" "${_pass_gen}");
  done
  echo "$(echo "${_pass_gen}" | cut -c "1-$(( ${_max_pass} + 1 ))")"
}

login_az
# JSON Web Token
# set automatically
# JWT_SECRET
az_save_secret "JwtSecret" "$(generate_secret)"

# signup required key phrase
# set automatically
# PRIVATE_KEY_PASSPHRASE
az_save_secret "PrivateKeyPassphrase" "$(generate_secret)"

# Should be set automatically
#  NEO4J_USERNAME: "YWRtaW4K"
#  NEO4J_PASSWORD: "YWRtaW4xMjNwYXNzCg=="
az_save_secret "Neo4jUsername" "$(generate_secret)"
az_save_secret "Neo4jPassword" "$(generate_secret)"

# required geo location api token https://api.mapbox.com/geocoding
# not auto generated, need to prompt comment
# MAPBOX_TOKEN:
echo "Setting MapBoxToken from MAPBOX_TOKEN env"
export MAPBOX_TOKEN="${MAPBOX_TOKEN:-}"
az_save_secret "MapBoxToken" "${MAPBOX_TOKEN:-$(echo "TU9OR09EQl9QQVNTV09SRA=="| base64 --decode)}"

# required for email messages, should be set manually
echo "Setting SmtpUsername from SMTP_USERNAME env"
export SMTP_USERNAME="${SMTP_USERNAME:-$(echo "cmVkc29sLmludGVybmF0aW9uYWxAZ21haWwuY29tCg=="| base64 --decode)}"
az_save_secret "SmtpUsername" "${SMTP_USERNAME}"

echo "Setting SmtpPassword from SMTP_PASSWORD env"
export SMTP_PASSWORD="${SMTP_PASSWORD:-$(echo "SnVzdGljaWE1Lgo="| base64 --decode)}"
az_save_secret "SmtpPassword" "${SMTP_PASSWORD}"