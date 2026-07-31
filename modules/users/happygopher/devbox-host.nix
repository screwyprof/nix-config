{ config, ... }:
{
  # The operator's home on the devbox NODE — the surface devbox does not manage.
  #
  # No containment here (an extension runs as the operator, with node privileges) and no isolation
  # available: the Remote-SSH server is per host+user, so every folder opened on the node shares one
  # extensions dir. Minimise and declare rather than isolate.
  flake.modules.homeManager.devbox-host =
    { pkgs, lib, ... }:
    let
      b = config.flake.lib.vscode.bundles pkgs;
      # The remote server + CLI, pinned to the same commit this editor negotiates. Placing them is what
      # stops Remote-SSH fetching ~635MB into this home on every fresh connect: both of its install gates
      # are existence checks, and a store symlink satisfies them.
      r = config.flake.lib.vscodeRemote pkgs;
    in
    {
      imports =
        with config.flake.modules.homeManager;
        [
          happygopher-identity
          dev-direnv
          dev-git
          # nix LSP + linters; nothing below depends on it.
          dev-nix
          core-vim
          cli-bat
          cli-eza
          cli-fzf
          cli-zoxide
          cli-zsh
        ]
        # The no-op supervisor that keeps the CLI from fetching a second, channel-latest server.
        ++ [ r.agentHostDecoy ];

      home = {
        # `happygopher`, not `happygopher.guest` — only the HOME PATH carries lima's suffix, and
        # home-manager validates this against $USER.
        username = "happygopher";
        homeDirectory = "/home/happygopher.guest";
        stateVersion = "24.11";

        # No `go` bundle: Go work happens in cages, which declare it themselves.
        file = lib.attrsets.unionOfDisjoint (config.flake.lib.vscode.mkServerLinks (
          b.base ++ b.rust
        )) r.serverFiles;
      };

      # Both surfaces' rebuild commands, kept out of the general `dev-nix` the Mac also imports. Both
      # are NODE commands — a cage has no machinectl to activate itself. Run from inside this repo.
      programs.zsh.initContent = lib.mkAfter ''
        function nix-rebuild-devbox() {
          local out
          out=$(nix build --no-link --print-out-paths ".#homeConfigurations.devbox-host.activationPackage") || return
          "$out/activate"
        }

        # STORE PATH, never ./result: a cage binds /nix/store but not this repo.
        function nix-rebuild-cage() {
          local project="$1"
          if [[ -z "$project" ]]; then
            echo "usage: nix-rebuild-cage <project>" >&2
            return 2
          fi
          local out
          out=$(nix build --no-link --print-out-paths ".#homeConfigurations.devbox-cage.activationPackage") || return
          sudo machinectl shell "dev@$project" /run/current-system/sw/bin/bash -lc "$out/activate"
        }
      '';

      # Login shell is bash here and in cages; home-manager supplies zsh in the user profile and bash
      # execs it for INTERACTIVE shells only, so scripts and `ssh <host> <cmd>` are unaffected.
      programs.bash = {
        enable = true;
        initExtra = ''
          if [[ $- == *i* ]] && [[ -z "$ZSH_VERSION" ]] && command -v zsh > /dev/null; then
            exec zsh -l
          fi
        '';
      };

      programs.home-manager.enable = true;
    };
}
