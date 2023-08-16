# Keychain Secrets manager

Command-line secrets manager powered by the Keychain tools already available on macOS systems.

It's a tiny, straightforward CLI that let's you securely store and retrieve encrypted secrets without any additional third parties involved.

It's built as a small wrapper around the native `security` command, so it's fast, secure, works offline and is fully interoperable with macOS keychains, which give you:
- A nice, built-in UI to manage your secrets ([Keychain Access](https://support.apple.com/en-ca/guide/keychain-access/kyca1083/mac) app).
- Optional backups, syncing and sharing with [iCloud Keychain](https://support.apple.com/en-ca/HT204085).
- Integration with some browsers and other keychain-compatible software.

<details><summary>Basic demo</summary>

https://github.com/loteoo/ks/assets/14101189/fec05de0-a5a7-47aa-9366-10ad20203eb8

</details>

## Installation

#### Install script

Use the install script for an easy, interactive installation by running this command:

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/loteoo/ks/main/install)"
```

#### Homebrew

You can also install ks using homebrew:

```sh
brew tap loteoo/formulas
brew install ks
```

<details><summary>Manual installation</summary>

1. Download the script file from github.
2. Place it into an executable directory that's in your $PATH. For instance, `~/.local/bin/ks`
3. Make sure the file is executable. `chmod +x ~/path/to/ks`
4. Run `ks init` to create a first keychain.

</details>

<details><summary>Contributor installation</summary>

Delete any other instance of the `ks` script on your machine.

Clone this repo somewhere on your machine, then create a symlink in a bin folder to the script:

```sh
#         This directory should be in your executable PATH
#                              /
ln -s ~/path/to/repo/ks/ks ~/bin/ks
#                        \
#       This should point to the actual ks file
```

Make sure the file is executable. `chmod +x ~/path/to/ks`.

</details>

You can also setup basic completions by adding `source <(ks completion)` to your shell profile.

## Usage

Use the `ks help` command to get an overview of the commands:

```
$ ks help
Keychain Secrets manager

Usage:
  ks [-k keychain] <command> [options]

Commands:
  add [-n] <key> [value]    Add a secret (-n for note)
  show <key>                Decrypt and reveal a secret
  cp <key>                  Copy secret to clipboard
  rm <key>                  Remove secret from keychain
  ls                        List secrets in keychain
  rand [size]               Generate random secret
  init                      Initialize selected keychain
  help                      Show this help text
  version                   Print version
```

### Add secrets

```sh
ks add my-secret 'password123'
# ⚠️ Note that this will add it to your shell history. ⚠️

# Add a secret from your clipboard:
pbpaste | ks add my-secret
# or
ks add my-secret "$(pbpaste)"

# Generate high-entropy secret:
ks rand | ks add my-secret
# or
ks add my-secret "$(ks rand)"

# Mark secret as a "note" to get a multi-line UI in Keychain Access app
cat long-text.txt | ks add -n my-secret-text
```

### Retrieve secrets

```sh
# Print out secret to stdout
ks show my-secret

# Copy secret to clipboard
ks cp my-secret
```

### Remove secrets

```sh
ks rm my-secret
```

### List secrets

```sh
ks ls

# You can filter with grep:
ks ls | grep 'prefix_'
```

## Using multiple keychains

By default, ks uses the `Secrets` keychain.

You can change this permanently by exporting a `KS_DEFAULT_KEYCHAIN` environment variable in your shell profile.
Ex: `export KS_DEFAULT_KEYCHAIN="AlternateKeychain"`

You can also work with multiple keychains with ks. You can pick them on a per-command basis by using the `-k` argument right after the ks command.

This allows you to pick from which keychain you want to run the ks commands on.

Examples:

```sh
# Create a "ProjectA" keychain
ks -k ProjectA init

# Create a "ProjectB" keychain
ks -k ProjectB init

ks -k ProjectA add some-password 'password123'
ks -k ProjectB add some-password 'hunter2'

ks -k ProjectA show some-password
# password123
ks -k ProjectB show some-password
# hunter2
```

## Who is this for

This is for you if:

- You're on macOS.
- You want to store and retrieve secrets using simple commands.
- You want to leverage OS functionnality.

> Bonus: You don't like the idea of relying on a HTTP request, a third party server and a credit card subscription to access your secrets.

---

PRs, issues, comments and ideas are welcome.

Give the repo a star if you like this! ❤️
