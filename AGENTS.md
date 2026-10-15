# Agent Guidelines

## Hard rules

- **Never deploy.** Do not run `deploy .#dfwk`, `deploy-rs`, `nixos-rebuild switch`,
  `systemctl restart`, `nixos-container ...` or anything else that applies this
  configuration to the host `dfwk.w1l.ru`. Building (`nix build`, `nix flake check`,
  `nix eval`) is fine; applying is not.
- **Never commit in git without a direct order from the user.** Do not run
  `git commit`, `git merge`, `git rebase`, `git push`, `git tag`, or amend
  history. `git add` / `git rm --cached` (staging) is fine. Creating a commit is
  only allowed when the user explicitly asks for it.

## Scope

This repo is the NixOS configuration for the `dfwk` host.

Files matched by `.gitignore` are **out of scope** — ignore them entirely and do
not read, edit, or account for them in your work.

## Conventions

- Flake: new files must be **tracked by git** to be visible to `nix` builds.
- Commit messages: `file: summary` per file changed.
- Verify changes with `nix build` / `nix flake check`, not by deploying.

## Build & inspect

- Whole host:    `nix build .#dfwkSystem.config.system.build.toplevel`
- One container: `nix build .#dfwkSystem.config.containers.<name>.config.system.build.toplevel`
- Checks:        `nix flake check`
- Clean up:      `rm result` after a build (untracked symlink, not ignored)

For a NixOS default or a generated file, read the *evaluated* config, not the
source. One eval at a time — parallel `nix eval` runs contend on the eval cache
("database ... is busy").

Several values in one eval:

```sh
nix eval --json .#dfwkSystem.config \
  --apply 'c: { mounts = c.containers.dfst.bindMounts;
                 backup = c.services.postgresqlBackup.databases; }'
```

A generated unit file — read `.text`, never `systemd.services.<unit>` itself
(its submodule forces sibling options and errors):

```sh
nix eval --raw \
  '.#dfwkSystem.config.containers.dfst.config.systemd.units."dfst-puma.service".text'
```

The pinned nixpkgs (NixOS module defaults live here, not in memory):

```sh
nix eval --raw .#dfwkSystem._module.args.pkgs.path
```

## Workflow

1. Make the change.
2. Build/eval it to verify (never deploy).
3. Leave changes staged; wait for the user to order a commit.
