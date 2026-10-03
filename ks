#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
VERSION="0.6.0"

_throw() { echo "$1" 1>&2; exit 1; }

_check() { [[ -n "${1:-}" && "$1" != *[!a-zA-Z0-9._-]* ]] || _throw "Specify a key of letters, digits, dots, dashes and underscores."; }

_sec() {
  key="$1"; shift
  err="$(security "$@" -s "$key" "$KEYCHAIN_FILE" 2>&1 1> /dev/null)" && return 0
  [[ "$err" == *"could not be found"* ]] || _throw "${err:-Keychain \"$KEYCHAIN\" is locked, or access to it was denied.}"
  return 1
}

_store() {
  _check "${2:-}"
  [[ -n "${3+x}" || ! -t 0 ]] || _throw "No value specified. Pass it as an argument or pipe it in."
  if _sec "$2" find-generic-password -a "$USER"; then [[ "$1" == update ]] || _throw "Secret \"$2\" already exists in keychain."
  else [[ "$1" == add ]] || _throw "Secret \"$2\" was not found in keychain."; fi
  if [[ -n "${3+x}" ]]; then value="$3"; else value="$(cat; printf .)"; value="${value%.}"; fi
  security add-generic-password -U -a "$USER" -s "$2" -w "$value" "$KEYCHAIN_FILE"
}

init() {
  if [[ -t 0 ]]; then security create-keychain "$KEYCHAIN_FILE"; else security create-keychain -p "$(cat)" "$KEYCHAIN_FILE"; fi
  security set-keychain-settings "$KEYCHAIN_FILE"
  KEYCHAIN_FILE="$(cd "${KEYCHAIN_FILE%/*}" && pwd -P)/${KEYCHAIN_FILE##*/}"
  security list-keychains -s $(security list-keychains | sed 's/^ *"//;s/"$//' | grep -vxF "$KEYCHAIN_FILE") "$KEYCHAIN_FILE"
}

add() { _store add "$@"; }

update() { _store update "$@"; }

show() {
  _check "${1:-}"
  _sec "$1" find-generic-password -g || _throw "Secret \"$1\" was not found in keychain."
  raw="${err##*$'\n'}"; raw="${raw#password: }"
  if [[ "$raw" == '"'*'"' ]]; then printf '%s' "${raw:1:${#raw}-2}"; else xxd -r -p <<< "${raw%% *}"; fi
  [[ ! -t 1 ]] || echo
}

cp() { value="$(show "$@"; printf .)" && printf '%s' "${value%.}" | pbcopy; }

rm() {
  _check "${1:-}"
  _sec "$1" delete-generic-password || _throw "Secret \"$1\" was not found in keychain."
}

ls() { security dump-keychain "$KEYCHAIN_FILE" | sed -n 's/^ *"svce"<blob>="\(.*\)"$/\1/p'; }

help() {
  cat << EOT
Keychain Secrets manager v$VERSION

Usage:
  ks [-k keychain] <command> [key] [value]

Commands:
  init                  Create the selected keychain
  add <key> [value]     Add a secret
  update <key> [value]  Change an existing secret
  show <key>            Decrypt and reveal a secret
  cp <key>              Copy secret to clipboard
  rm <key>              Remove secret from keychain
  ls                    List secrets in keychain
  help                  Show this help text

https://github.com/loteoo/ks
EOT
}


KEYCHAIN="${KS_KEYCHAIN:-Secrets}"
if [[ "${1:-}" == -k && -n "${2:-}" ]]; then KEYCHAIN="$2"; shift 2; fi
KEYCHAIN_FILE="$KEYCHAIN"
[[ "$KEYCHAIN_FILE" == *.keychain-db ]] || KEYCHAIN_FILE="$KEYCHAIN_FILE.keychain-db"
[[ "$KEYCHAIN_FILE" == */* ]] || KEYCHAIN_FILE="$HOME/Library/Keychains/$KEYCHAIN_FILE"
[[ "$KEYCHAIN_FILE" == /* ]] || KEYCHAIN_FILE="$PWD/$KEYCHAIN_FILE"
[[ "${2:-}" != -k ]] || _throw "The -k option must come before the command."


case "${1:-}" in
  add|update|show|cp|rm|ls)
    [[ -f "$KEYCHAIN_FILE" ]] || _throw "Keychain \"$KEYCHAIN\" was not found. Create it with \"ks init\"."
    "$@";;
  init|help) "$@";;
  *) _throw "$(help)";;
esac
