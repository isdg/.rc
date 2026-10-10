# Debian VM (Lima)

A persistent Debian 13 VM with this repo bootstrapped inside, the same on
every Mac: `debian.yaml` pins the image and resources, and its first boot
clones `.rc` and runs `boot.sh --level=3`. Nothing here runs from the Mac's
own bootstrap; you launch it by hand.

Inside, you are `isg` with passwordless sudo, your home is `/home/isg.guest`
(Lima's naming), and the machine names itself `isg-debian-<postfix>`, like
any bootstrapped box.

## Prerequisites

Lima, which the Brewfile already installs (with colima):

```sh
limactl --version
```

## Create and start

```sh
limactl start --name=debian --timeout=40m \
  --param Postfix="$(cat ~/.config/isg/postfix)" \
  ~/.rc/lima/debian.yaml
```

- `--name=debian`: Lima's instance name (`limactl shell debian`).
- `--timeout=40m`: `limactl start` waits for the first-boot bootstrap. Level
  3 took about 5 minutes on an M5 Pro, but a slow network can push it past
  Lima's default 10. A timeout only stops the waiting; the VM keeps going.
- `--param Postfix=...`: names the VM after this Mac (`isg-debian-sigma` on
  sigma). Leave it out for a random Greek letter.

Other parameters:

| Parameter | Default | Meaning |
|---|---|---|
| `Level` | `3` | `boot.sh --level` inside the VM |
| `Postfix` | empty (random) | the hostname's last word |
| `Repo` | GitHub's `isdg/.rc` | what to clone (see below) |

`Repo` also takes a path under the Mac home, which the VM sees mounted:
`--param Repo=$HOME/.rc` bootstraps from commits you have not pushed.

Follow the first boot from another terminal:

```sh
limactl shell debian sudo tail -f /var/log/cloud-init-output.log
```

## Daily use

```sh
limactl shell debian            # a shell inside (zsh, your setup)
limactl list                    # instances and their state
limactl stop debian             # clean shutdown; the disk stays
limactl start debian            # boot again: no bootstrap, seconds
```

Plain ssh works too, with your agent forwarded:

```sh
ssh -F ~/.lima/debian/ssh.config lima-debian
```

Ports a program opens inside the VM are forwarded to `localhost` on the Mac
automatically. The Mac home is mounted read-only at its usual path
(`/Users/isg`).

`boot.sh --ensure` inside reports what the VM lacks on purpose: no Go or Rust,
so no `hr`, `plc`, `omni` or `orchbus`, and no `ewl`, a private repo the
first boot clones without your ssh agent. Run `boot.sh` again from a
`limactl shell` session, where the agent is forwarded, to fetch `ewl`.

## Updating the setup inside

The bootstrap runs once, on the first boot. Afterwards, as on any machine:

```sh
cd ~/.rc && git pull && .rcboot/boot.sh
```

## Start from scratch

```sh
limactl delete --force debian
```

then create it again. Work you keep inside the VM goes with it, so keep it in
git.
