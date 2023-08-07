#!/usr/bin/env bash

add() {
  if [[ -z ${1+x} ]]; then
    throw "No key specified. Please provide the name of the secret to add."
  fi
  if [[ -n "${2+x}" ]]; then
    value="$2"
  elif [[ ! -t 0 ]]; then
    value="$(cat)"
  else
    throw "No secret specified. Please provide the value to encrypt."
  fi
  security add-generic-password \
    -a "$USER" \
    -s "$1" \
    -D secret \
    -w "$value" \
    "$KEYCHAIN_FILE" \
    2> /dev/null \
    || throw "Secret \"$1\" already exists."
  success "Secret \"$1\" added."
}

show() {
  if [[ -z ${1+x} ]]; then
    throw "No key specified. Please provide the name of the secret to show."
  fi
  raw_pass="$(
    security find-generic-password \
      -a "$USER" \
      -s "$1" \
      -g \
      "$KEYCHAIN_FILE" \
      2>&1 1>/dev/null \
      tail -1 \
      || throw "Secret \"$1\" was not found in keychain."
  )"
  raw_pass="${raw_pass#password: }"
  if [[ "$raw_pass" = "\""*"\"" ]]; then
    raw_pass="${raw_pass%\"}"
    raw_pass="${raw_pass#\"}"
    echo "$raw_pass"
  else
    echo "$raw_pass" \
      | cut -d' ' -f1 \
      | xxd -r -p
    echo
  fi
}

rm() {
  if [[ -z ${1+x} ]]; then
    throw "No key specified. Please provide the name of the secret to remove."
  fi
  security delete-generic-password  \
    -a "$USER" \
    -s "$1" \
    "$KEYCHAIN_FILE" \
    > /dev/null 2>&1 \
    || throw "Secret \"$1\" was not found in keychain."
  success "Secret \"$1\" deleted."
}

ls() {
  security dump-keychain "$KEYCHAIN_FILE" \
    | grep 0x00000007 \
    | awk -F= '{print $2}' \
    | tr -d \" \
    || throw "No secrets found. Keychain is empty."
}

init() {
  maybe_error="$(cat <(security show-keychain-info "$KEYCHAIN_FILE" 2>&1))"
  not_found_error="The specified keychain could not be found"
  if [[ "$maybe_error" == *"SecKeychainCopySettings"* ]]; then
    if [[ "$maybe_error" == *"$not_found_error"* ]]; then
      if ! yn "Keychain \"$KEYCHAIN\" does not exist. Create it?"; then
        throw "Aborted."
      fi
      if [[ "$KEYCHAIN" =~ [^a-zA-Z0-9_-] ]]; then
        throw "Invalid keychain name. Alphanumeric with dashes and underscores only."
      fi
      echo "Choose a password for the keychain. You can change it later via the Keychain Access app."
      read -rsp "Password: " pass
      echo
      security create-keychain -p "$pass" "$KEYCHAIN_FILE"
      success "Keychain \"$KEYCHAIN\" created."
      if yn "Register in Keychain Access app?"; then
        eval "security list-keychains -s $(security default-keychain) $(security list-keychains | xargs) $HOME/Library/Keychains/$KEYCHAIN_FILE"
        success "Keychain \"$KEYCHAIN\" added to Keychain Access app."
      fi
    else
      throw "Could not access the \"$KEYCHAIN\" keychain."
    fi
  fi
}

# Meta stuff...
# ===================
set -euo pipefail
IFS=$'\n\t'
normal=$(tput sgr0)
cyan=$'\e[96m'

KEYCHAIN="${KS_DEFAULT_KEYCHAIN:-Secrets}"

help() {
  cat << EOT
Keychain Secrets manager

Usage:
  ks [-k keychain] <action> [...opts]

Commands:
  add <key> <value>  Add an encrypted secret
  show <key>         Decrypt and reveal a secret
  rm <key>           Remove a secret
  ls                 List secret keys
  init               Create the specified Keychain
  help               Show this help text
EOT
}

completion() {
  echo "complete -W \"add show rm ls help\" ks"
}

success() {
  # shellcheck disable=SC2145
  echo "${cyan}✓ $@${normal}"
}

throw() {
  echo "$@" 1>&2
  exit 1
}

yn() {
  read -r -n 1 -p "$1 [y/n]: " yn
  echo
  if [[ "$yn" != [Yy]* ]]; then
    return 1
  fi
}

while getopts "k:" arg; do
  case $arg in
    k) KEYCHAIN="$OPTARG";;
    *) throw "$(help)";;
  esac
done
shift $((OPTIND - 1))

KEYCHAIN_FILE="$KEYCHAIN.keychain"

if [[ "$(type -t "${1:-}")" == "function" ]]; then
  if [[ "add show rm ls" = *"$1"* ]]; then
    init
  fi
  $1 "${@:2}"
else
  throw "$(help)"
fi
