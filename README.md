<a href="https://millisecond.studio/">
  <img src="https://cdn.thumbsmith.com/v1/u/loteoo/millisecond-github-banner.png?title=ks+-+Keychain+Secrets+manager&description=Command-line+secrets+manager+powered+by+macOS+keychains" alt="ks banner" />
</a>

---

`ks` is a macOS CLI for storing secrets in Keychain through Apple's `security` command. No account, no server, no third party: it works offline, and stores plain generic-password items that stay interoperable with the rest of macOS, which gives you:

- A built-in UI for your secrets, the [Keychain Access](https://support.apple.com/en-ca/guide/keychain-access/kyca1083/mac) app.
- Backup and sync through iCloud, Google Drive, NextCloud, etc. See [iCloud sync](#icloud-sync).

## Install

With Homebrew:

```sh
brew tap loteoo/formulas
brew install ks
```

Manual install:

```sh
mkdir -p "$HOME/.local/bin"
curl -fsSL https://raw.githubusercontent.com/loteoo/ks/main/ks -o "$HOME/.local/bin/ks"
chmod +x "$HOME/.local/bin/ks"
```

## Usage

Run `ks help` for the command list.

```sh
ks init
pbpaste | ks add my-api-key # Add from clipboard via stdin
ks add my-secret secret123 # Warning: Most default shell configurations will save this in history
ks show my-secret
ks cp my-secret
ks ls
ks rm my-secret
openssl rand -hex 32 | ks add my-secret # Generate & add secret
openssl rand -hex 32 | ks update my-secret # Rotate secret
ks show old-name | ks add new-name && ks rm old-name # Rename name in ks
```


### Keychains

`ks` defaults to `Secrets` -> `~/Library/Keychains/Secrets.keychain-db`.

Select another keychain with `-k` or `KS_KEYCHAIN`. Both accept a name or an absolute `.keychain-db` path; `init` can create either.

```sh
ks -k ProjectA init
ks -k ProjectA add token < token.txt
ks -k "$HOME/Library/Keychains/ProjectA.keychain-db" ls
export KS_KEYCHAIN=ProjectA
security delete-keychain ProjectA
```

### iCloud sync

A keychain is a single file, so any file-syncing service backs it up and shares it between machines: move the file into the synced folder, then symlink it back where macOS looks for it.

```sh
ks -k iCloud init
CLOUD_FOLDER="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
mv "$HOME/Library/Keychains/iCloud.keychain-db" "$CLOUD_FOLDER/iCloud.keychain-db"
ln -s "$CLOUD_FOLDER/iCloud.keychain-db" "$HOME/Library/Keychains/iCloud.keychain-db"
```

On each machine, wait for the file to land in iCloud Drive, then create the same symlink. Creating and deleting a folder forces iCloud to refresh.

### Coding agents

For unattended access, give agents their own keychain, with an empty password or one you store where the agent can read it. Either way the file has no meaningful password protection: put only credentials you accept storing that way in it.

```sh
printf '' | ks -k Agents init
ks -k Agents add token < token.txt
security unlock-keychain -p '' "$HOME/Library/Keychains/Agents.keychain-db"
```

macOS locks the keychain on logout or reboot. Unlock it once after login before the agent accesses it; `ks init` turns off idle and sleep locking. To unlock it when a zsh login shell starts, add the `security unlock-keychain` line above to your `~/.zprofile`, or equivalent.


### Completion

Completing keys reads the keychain, so the first TAB on a locked one pops the unlock dialog, and completes silently once unlocked. Keys come from the keychain in `KS_KEYCHAIN`; a `-k` on the command line is ignored.

<details>
<summary>zsh — add in your profile (eg: .zprofile), after <code>compinit</code></summary>

```sh
_ks() {
  if (( CURRENT == 2 )); then
    compadd init add update show cp rm ls help
  elif (( CURRENT == 3 )) && [[ "$words[2]" == (show|cp|rm|update) ]]; then
    compadd -- ${(f)"$(ks ls 2>/dev/null)"}
  fi
}
compdef _ks ks
```

</details>

<details>
<summary>bash — add in your profile (eg: .bash_profile)</summary>

```sh
_ks() {
  case "$COMP_CWORD:${COMP_WORDS[1]}" in
    1:*) COMPREPLY=($(compgen -W "init add update show cp rm ls help" -- "$2"));;
    2:show|2:cp|2:rm|2:update) COMPREPLY=($(compgen -W "$(ks ls 2>/dev/null)" -- "$2"));;
  esac
}
complete -F _ks ks
```

### Keychain Access app

https://github.com/loteoo/ks/assets/14101189/fec05de0-a5a7-47aa-9366-10ad20203eb8


</details>

## Who is this for

You're on macOS, you want to store and read secrets with short commands, and you'd rather not put an HTTP request, a third-party server and a subscription between you and your own credentials.

---

PRs, issues, comments and ideas are welcome. Give the repo a star if you like this.

Crafted by [millisecond studio](https://millisecond.studio/) ❤️

[MIT license](LICENSE).
