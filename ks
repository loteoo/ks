#!/usr/bin/env bash

add() {
  key="${1:?'Please provide the name of the secret to add.'}"
  value="${2:?'Please provide the value to encrypt.'}"
  security add-generic-password \
    -a "$USER" \
    -D secret \
    -s "$key" \
    -w "$value" \
    "$KEYCHAIN_FILE" \
    2> /dev/null \
    || throw "Secret \"$key\" already exists."
  success "Secret \"$key\" added."
}

show() {
  key="${1:?'Please provide the name of the secret to show.'}"
  security find-generic-password \
    -a "$USER" \
    -s "$key" \
    -w \
    "$KEYCHAIN_FILE" \
    2> /dev/null \
    || throw "Secret \"$key\" was not found in keychain."
}

rm() {
  key="${1:?'Please provide the name of the secret to remove.'}"
  security delete-generic-password  \
    -a "$USER" \
    -s "$key" \
    "$KEYCHAIN_FILE" \
    > /dev/null 2>&1 \
    || throw "Secret \"$key\" was not found in keychain."
  success "Secret \"$key\" deleted."
}

ls() {
  security dump-keychain "$KEYCHAIN_FILE" \
    | grep 0x00000007 \
    | awk -F= '{print $2}' \
    | tr -d \" \
    || throw "Keychain is empty."
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
