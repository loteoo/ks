#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
VERSION="0.3.0"

# Commands
# ==========

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
    echo -n "$raw_pass"
  else
    echo "$raw_pass" \
      | cut -d' ' -f1 \
      | xxd -r -p
  fi
}

cp() {
  show "$@" | pbcopy
  success "Secret \"$1\" copied to clipboard."
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
  success "Secret \"$1\" removed."
}

ls() {
  security dump-keychain "$KEYCHAIN_FILE" \
    | grep 0x00000007 \
    | awk -F= '{print $2}' \
    | tr -d \" \
    || throw "No secrets found. Keychain is empty."
}

rand() {
  size="${1:-32}"
  if ! [[ $size =~ ^[0-9]+$ ]] ; then
    throw "Size \"$size\" is not a valid integer."
  fi
  secret="$(openssl rand -hex "$(((size+1) / 2))")"
  echo "${secret:0:$size}"
}

init() {
  maybe_error="$(cat <(security show-keychain-info "$KEYCHAIN_FILE" 2>&1))"
  not_found_error="The specified keychain could not be found"
  if [[ "$maybe_error" == *"SecKeychainCopySettings"* ]]; then
    if [[ "$maybe_error" == *"$not_found_error"* ]]; then
      if ! yn "The \"$KEYCHAIN\" keychain does not exist. Do you want to create it?"; then
        throw "Aborted."
      fi
      if [[ "$KEYCHAIN" =~ [^a-zA-Z0-9_-] ]]; then
        throw "Invalid keychain name. Alphanumeric with dashes and underscores only."
      fi
      echo "Choose a password for the keychain. You can change it later via the Keychain Access app."
      while true; do
        read -rsp "Password: " password
        echo
        if [[ "${#password}" -lt "3" ]]; then
          info "Passwords is too short".
          continue
        fi
        read -rsp "Confirm password: " confirm_password
        echo
        if [[ "$password" != "$confirm_password" ]]; then
          info "Passwords don't match".
          continue
        fi
        break
      done
      security create-keychain -p "$password" "$KEYCHAIN_FILE"
      success "Keychain \"$KEYCHAIN\" created."
      if yn "Register in Keychain Access app?"; then
        eval "security list-keychains -s $(security default-keychain) $(security list-keychains | xargs) $HOME/Library/Keychains/$KEYCHAIN_FILE"
        success "Keychain \"$KEYCHAIN\" added to Keychain Access app."
      fi
    else
      throw "Could not access the \"$KEYCHAIN\" keychain."
    fi
  else
    if [[ "${1:-}" != '-q' ]]; then
      info "Keychain \"$KEYCHAIN\" already exists."
    fi
  fi
}

help() {
  cat << EOT
Keychain Secrets manager v$VERSION

Usage:
  ks [-k keychain] <command> [options]

Commands:
  add <key> [value]     Add an encrypted secret
  show <key>            Decrypt and reveal a secret
  cp <key>              Copy secret to clipboard
  rm <key>              Remove secret from keychain
  ls                    List secrets in keychain
  rand [size]           Generate random secret
  init                  Initialize selected keychain
  help                  Show this help text
  version               Print version
EOT
}

version () {
  echo "$VERSION"
}

completion() {
  echo "complete -W \"add show cp rm ls rand init help version\" ks"
}


# Utilities
# ===========
normal=$'\e[0m'
dimmed=$'\e[2m'
cyan=$'\e[96m'

info() {
  # shellcheck disable=SC2145
  echo "${dimmed}$@${normal}" 1>&2
}
success() {
  # shellcheck disable=SC2145
  echo "${cyan}✓ $@${normal}"
}
throw() {
  # shellcheck disable=SC2145
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


# Parse CLI shared options
# ==========================

KEYCHAIN="${KS_DEFAULT_KEYCHAIN:-Secrets}"
while getopts "k:" arg; do
  case $arg in
    k) KEYCHAIN="$OPTARG";;
    *) throw "$(help)";;
  esac
done
shift $((OPTIND - 1))
KEYCHAIN_FILE="$KEYCHAIN.keychain"


# Execute sub-command
# =====================
if [[ "$(type -t "${1:-}")" == "function" ]]; then
  if [[ "add show cp rm ls" = *"$1"* ]]; then
    init -q
  fi
  "$@"
else
  throw "$(help)"
fi
