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
ks init # create keychain file
ks add my-secret # prompts for the value
ks add my-api-key "$(pbpaste)" # add from clipboard
pbpaste | ks add my-token # add from stdin
ks show my-secret
ks cp my-secret
ks ls
ks rm my-secret
openssl rand -hex 32 | ks add my-secret # generate & add secret
openssl rand -hex 32 | ks update my-secret # rotate secret
ks show old-name | ks add new-name && ks rm old-name # rename a key
```

### Keychains

Specify the keychain with `-k` or `KS_KEYCHAIN`, as a name or an absolute `.keychain-db` path.

Named keychains are stored in the `~/Library/Keychains/` folder.

The default is `Secrets` -> `~/Library/Keychains/Secrets.keychain-db`.

```sh
ks -k ProjectA init
ks -k ProjectA add token < token.txt
ks -k "$HOME/Library/Keychains/ProjectA.keychain-db" ls
export KS_KEYCHAIN=ProjectA
security delete-keychain ProjectA.keychain-db
```

### iCloud sync

A keychain is a single file, so any file-syncing service backs it up and shares it between machines: move the file into the synced folder, then symlink it back where macOS looks for it.

```sh
ks -k iCloud init
CLOUD_FOLDER="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
mv "$HOME/Library/Keychains/iCloud.keychain-db" "$CLOUD_FOLDER/iCloud.keychain-db"
ln -s "$CLOUD_FOLDER/iCloud.keychain-db" "$HOME/Library/Keychains/iCloud.keychain-db"
```

On each machine, wait for the file to land in iCloud Drive, then create the same symlink.

### Coding agents

Agents can use any unlocked keychain, so the problem is unlocking it without you. macOS unlocks the `login` keychain when you log in: store your other keychains' passphrases there, and unlock them from your `~/.zprofile` or from your agent's instructions. Think carefully about what blast radius you create when giving secrets to LLM agents.

```sh
ks -k login add ProjectA-passphrase
security unlock-keychain -p "$(ks -k login show ProjectA-passphrase)" ProjectA.keychain-db
```

## Terminal tips

### fzf tricks

For [fzf](https://github.com/junegunn/fzf) users, here are some tips:

```sh
ks ls | fzf | pbcopy # search & copy a key
ks cp $(ks ls | fzf) # search & copy a value by key

# search with a masked preview of the value, then copy it; accepts -k
ks-fzf() {
  local key
  key=$(ks "$@" ls | fzf --preview "ks $* show {} | sed -E 's/^(..).+(..)\$/\1***\2/;s/^.{1,4}\$/***/'" --preview-window=down,3,wrap) && ks "$@" cp "$key"
}
```

### Skip shell history

bash and zsh have an option to skip writing a command to the shell history when it starts with a space. This way, you can type ` ks add my-secret mysecret123` (note the space at the beginning) without having the value leak to your shell history. If it interests you, add these to your shell profile:

```sh
# for zsh
setopt HIST_IGNORE_SPACE

# for bash
HISTCONTROL=ignorespace
# alternatively, use "ignoreboth" to skip spaces and duplicate commands
```

### Completion

Here's a tab-completion script you can use for zsh/bash. Completing keys reads the keychain, so the first TAB on a locked one pops the unlock dialog, and completes silently once unlocked. Keys come from the keychain in `KS_KEYCHAIN`.

Add this to your interactive shell config (`.zshrc` or `.bashrc`):

```sh
[[ -n $ZSH_VERSION ]] && autoload -Uz bashcompinit && bashcompinit # after compinit
_ks() {
  case "$COMP_CWORD:${COMP_WORDS[@]:1:1}" in
    1:*) COMPREPLY=($(compgen -W "init add update show cp rm ls help" -- "$2"));;
    2:show|2:cp|2:rm|2:update) COMPREPLY=($(compgen -W "$(ks ls 2>/dev/null)" -- "$2"));;
  esac
}
complete -F _ks ks
```

## Keychain Access app

macOS ships with the Keychain Access app, which gives your keychains a GUI.

https://github.com/loteoo/ks/assets/14101189/fec05de0-a5a7-47aa-9366-10ad20203eb8

## Who is this for

You're on macOS, you want to store and read secrets with short commands, and you'd rather not put an HTTP request, a third-party server and a subscription between you and your own credentials.

---

PRs, issues, comments and ideas are welcome. Give the repo a star if you like this.

Crafted by [millisecond studio](https://millisecond.studio/) ❤️

[MIT license](LICENSE).
