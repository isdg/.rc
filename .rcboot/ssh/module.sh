#!/usr/bin/env bash
# Module: ssh client config.

# Unlike the gpg one this is not Darwin-guarded: the only Darwin-only keyword in
# it, UseKeychain, is wrapped in IgnoreUnknown so a Linux ssh skips it rather
# than dying on it. The file only -- keys and known_hosts stay out of the repo.
link ssh/config "$HOME/.ssh/config"

# _relink's `mkdir -p` makes a missing parent at the umask, i.e. 0755. ssh
# refuses a private key whose directory is group- or world-readable, so a 0755
# ~/.ssh would break every key put in it later.
secure_ssh_dir() {
    if [ -d "$HOME/.ssh" ]; then
        chmod 700 "$HOME/.ssh"
    fi
}
hook secure_ssh_dir
