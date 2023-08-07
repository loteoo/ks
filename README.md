# Keychain Secrets manager

Command-line secrets manager powered by the Keychain tools already available on macOS systems.

It's a tiny, straightforward CLI that let's you securely store and retrieve encrypted secrets without any additional third parties involved.

It's built as a small wrapper around the native `security` command, so it's fast, works offline and is fully interoperable with the Keychain Access app. This way you can also manage your secrets via a UI as well.

This is for you if:

- You're on macOS.
- You want to store and retrieve secrets using simple commands.
- You like leveraging native OS functionnality.

> Bonus: You don't like the idea of relying on HTTP requests, a third party company and a credit card subscription to manage secrets.

<details><summary>Basic demo</summary>

https://github.com/loteoo/ks/assets/14101189/fec05de0-a5a7-47aa-9366-10ad20203eb8

</details>

## Installation

Use the install script for an automated, interactive installation:

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/loteoo/ks/main/install)"
```

This script is safe to re-run multiple times if your installation becomes corrupted for some reason, or to update to the latest version.

I'll eventually publish this on homebrew.

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

You can also setup basic completion by adding `source <(ks completion)` in your shell profile.

## Usage

Use the `ks help` command to get an overview of the commands:

```
$ ks help
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
```

### Add secrets

```sh
ks add my-secret 'password123'
# Note that this will add it to your shell history.

# Add a secret from your clipboard:
pbpaste | ks add my-secret
# or
ks add my-secret "$(pbpaste)"

# Generate high-entropy secret:
openssl rand -hex 24 | ks add my-secret
```

### Retrieve secrets

```sh
ks show my-secret

# Or to your clipboard:
ks show my-secret | pbcopy
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

If you have multiple keychains, you can pick them on a per-command basis by using the `-k` argument right after the ks command.

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

PRs, issues, comments and ideas are appreciated.

Give the repo a star to show your support! ❤️
