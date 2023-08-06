# Keychain Secrets manager

Straight-forward command line secrets manager powered by the Keychain tools already available on macOS systems.

It's a tiny and easy to use CLI that let's you securely store and retrieve encrypted secrets from a Keychain without any additional third parties involved.

It's built as a small wrapper around native `security` command, so it's fast, works offline and is fully interoperable with the Keychain Access app. This way you can also manage your secrets via the UI as well.

**This is for you if**:

- You're on macOS.
- You want to store and retrieve secrets via the command-line using simple commands.
- You like leveraging existing OS functionnality.
- You don't like the idea of relying on an HTTP connection, a third party service and a credit card subscription to manage secrets.

## Installation

Use the install script for an simple interactive installation, that will, in short:

1. Download the script file from github.
2. Place it into the chosen executable path and make sure it's executable.
3. Create a Keychain to store secrets in and register it in Keychain Access app.

```sh
curl -sSLf https://raw.githubusercontent.com/loteoo/ks/main/install | bash
```

## Manual installation

Clone this repo somewhere on your machine, then create a symlink in your executable bin folder to the script.

```sh
#         This directory should be in your executable PATH
#                           /
ln -s ~/path/to/repo/ks ~/bin/ks
#                     \
#       This should point to the actual secret file
```

To setup completions run something like this:

```sh
echo "source <(ks completion)" >> ~/.zshrc
```

## Usage

```
$ ks help
Keychain Secrets manager

Usage:
  ks add <key> <value>  Add an encrypted secret
  ks show <key>         Decrypt and reveal a secret
  ks ls                 List secret keys
  ks rm <key>           Remove a secret
  ks help
```
