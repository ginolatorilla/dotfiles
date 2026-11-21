# Dotfiles

Personal configuration and software lists that set up the home directory of each Machine the owner uses, on macOS and Linux.

## Language

### Where things go

**Machine**:
One operating-system install whose home directory this repo sets up, such as a Mac, a WSL distro or a Linux computer. A Windows PC that runs WSL hosts a Machine but is not one.
_Avoid_: host, laptop, box

**Platform**:
The operating-system family of a Machine: macOS or Linux. WSL counts as Linux.
_Avoid_: OS, environment

### What gets set up

**Dotfile**:
A configuration file this repo places in a Machine's home directory.
_Avoid_: config, config file

**Package**:
Software this repo installs on a Machine, whatever installer it uses.
_Avoid_: tool, app

**Local override**:
An untracked file on one Machine that a Dotfile includes, holding settings or Packages that are specific to that Machine or Private.
_Avoid_: vars, host vars

### What stays out of the repo

**Private**:
Describes a setting or Package that a Machine may have but the public repo must not name, such as an internal tool or an organisation's name. Private items live only in Local overrides.
_Avoid_: employer, work, internal, confidential

**Secret**:
A credential, such as a private key or a token. Secrets are never stored in the repo or in Local overrides.
_Avoid_: private (for credentials)
