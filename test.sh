#!/usr/bin/env bash
set -euo pipefail

read -r -p 'Tests change the keychain search list and clipboard. Continue? [y/N] ' answer
[[ "$answer" == [yY] ]] || exit 0

tmp="$(mktemp -d /tmp/ks-test.XXXXXX)"
keychain="$tmp/Test Keychain.keychain-db"
ks="$(cd "$(dirname "$0")" && pwd)/ks"
original=()
while IFS= read -r line; do
  line="${line#*\"}"
  original+=("${line%\"}")
done < <(security list-keychains -d user)
cleanup() {
  security delete-keychain "$keychain" >/dev/null 2>&1 || true
  rm -rf "$tmp"
  security list-keychains -d user -s "${original[@]}" >/dev/null
}
trap cleanup EXIT
trap 'exit 1' INT TERM

# init creates the keychain file
printf '' | "$ks" -k "$keychain" init
[[ -f "$keychain" ]] || { echo 'init did not create the keychain' >&2; exit 1; }
# init registers the keychain once, even when re-created over a deleted file
rm -f "$keychain"
printf '' | "$ks" -k "$keychain" init
[[ "$(security list-keychains -d user | grep -c 'Test Keychain')" == 1 ]] || { echo 'init duplicated the search list entry' >&2; exit 1; }
# add stores a value; show reads it back through KS_DEFAULT_KEYCHAIN
"$ks" -k "$keychain" add example 'initial secret'
[[ "$(KS_DEFAULT_KEYCHAIN="$keychain" "$ks" show example)" == 'initial secret' ]] || { echo 'add/show failed' >&2; exit 1; }
# ls lists the key
[[ "$("$ks" -k "$keychain" ls)" == example ]] || { echo 'ls failed' >&2; exit 1; }
# cp puts the value on the clipboard
"$ks" -k "$keychain" cp example
[[ "$(pbpaste)" == 'initial secret' ]] || { echo 'cp failed' >&2; exit 1; }
# add on an existing key fails and keeps the old value
if "$ks" -k "$keychain" add example replacement > "$tmp/output" 2>&1; then echo 'duplicate add succeeded' >&2; exit 1; fi
[[ "$(< "$tmp/output")" == 'Secret "example" already exists in keychain.' ]] || { echo 'duplicate add error changed' >&2; exit 1; }
[[ "$("$ks" -k "$keychain" show example)" == 'initial secret' ]] || { echo 'duplicate add overwrote secret' >&2; exit 1; }
# update on a missing key fails with the not-found message
if "$ks" -k "$keychain" update missing replacement > "$tmp/output" 2>&1; then echo 'missing-key update succeeded' >&2; exit 1; fi
[[ "$(< "$tmp/output")" == 'Secret "missing" was not found in keychain.' ]] || { echo 'missing-key update error changed' >&2; exit 1; }
# cp on a missing key fails and leaves the clipboard alone
if "$ks" -k "$keychain" cp missing > "$tmp/output" 2>&1; then echo 'missing-key cp succeeded' >&2; exit 1; fi
[[ "$(pbpaste)" == 'initial secret' ]] || { echo 'missing-key cp changed clipboard' >&2; exit 1; }
# update round-trips a multiline value byte for byte
printf 'updated\nvalue\n' | "$ks" -k "$keychain" update example
"$ks" -k "$keychain" show example > "$tmp/actual"
printf 'updated\nvalue\n' > "$tmp/expected"
cmp "$tmp/expected" "$tmp/actual" || { echo 'update lost bytes' >&2; exit 1; }
# piped output carries no trailing newline of its own
printf 'no-newline' | "$ks" -k "$keychain" update example
[[ "$("$ks" -k "$keychain" show example | xxd -p)" == '6e6f2d6e65776c696e65' ]] || { echo 'show added bytes when piped' >&2; exit 1; }
# a locked keychain fails with a message rather than in silence
security lock-keychain "$keychain"
if "$ks" -k "$keychain" show example > "$tmp/output" 2>&1; then echo 'locked show succeeded' >&2; exit 1; fi
[[ -s "$tmp/output" ]] || { echo 'locked show failed silently' >&2; exit 1; }
security unlock-keychain -p '' "$keychain"
# rm deletes the key
"$ks" -k "$keychain" rm example
[[ -z "$("$ks" -k "$keychain" ls)" ]] || { echo 'rm failed' >&2; exit 1; }
# version is not a command
if "$ks" version > "$tmp/output" 2>&1; then echo 'version is still a command' >&2; exit 1; fi
# help succeeds
"$ks" help > "$tmp/output"
echo 'Tests passed.'
