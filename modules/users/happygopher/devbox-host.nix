{ config, ... }:
{
  # The operator's home ON THE DEVBOX NODE (`happygopher.guest` in the VM).
  #
  # This surface exists because devbox does NOT manage it. Cages get their extension set from their
  # project's session flake at `up`; the node home has no project and no `up`, so today it is nine
  # imperatively-installed directories that nothing reproduces or prunes.
  #
  # It is also the one tier with NO containment — an extension here runs as the operator, on the node,
  # with node privileges — so it is where a small declared set matters most per extension. Deliberately
  # not per-project: the Remote-SSH server is per host+user, so every folder opened on the node shares
  # one extensions dir. Isolation is unavailable here at any sane price, and would buy little for a
  # workspace that can already `sudo`. The answer for this tier is MINIMISE + DECLARE, not isolate.
  flake.modules.homeManager.devbox-host =
    { pkgs, lib, ... }:
    let
      b = config.flake.lib.vscode.bundles pkgs;
    in
    {
      imports = with config.flake.modules.homeManager; [
        happygopher-identity
        dev-direnv
        dev-git
        # nil / statix / deadnix / nixpkgs-fmt. An independent choice, not a dependency of anything
        # below: the node is where the devbox repo (all nix) gets edited. Drop it if you disagree.
        dev-nix
        core-vim
        cli-bat
        cli-eza
        cli-fzf
        cli-zoxide
        cli-zsh
      ];

      home = {
        # `happygopher`, NOT `happygopher.guest` — only the HOME PATH carries lima's `.guest` suffix
        # (`passwd: user=happygopher home=/home/happygopher.guest`). home-manager validates this against
        # $USER, so the mismatch would have failed at activation.
        username = "happygopher";
        homeDirectory = "/home/happygopher.guest";
        stateVersion = "24.11";

        # base + rust: the node hosts devbox development, which is a Rust and nix repo. No `go` bundle —
        # Go work happens in cages, which declare it themselves.
        file = config.flake.lib.vscode.mkServerLinks (b.base ++ b.rust);
      };

      # The rebuild commands for BOTH surfaces live here, not in `dev-nix`: they are devbox-specific and
      # `dev-nix` is a general module the Mac imports too. They are also both NODE commands —
      # `nix-rebuild-cage` builds the cage generation here and shells in to activate it, which a cage
      # cannot do for itself (no machinectl, no host systemd) — so this profile is the one place they
      # belong. Same `.#` convention as `nix-rebuild`: run them from inside this repo.
      programs.zsh.initContent = lib.mkAfter ''
        function nix-rebuild-devbox() {
          local out
          out=$(nix build --no-link --print-out-paths ".#homeConfigurations.devbox-host.activationPackage") || return
          "$out/activate"
        }

        # Pass the STORE PATH, never ./result: a cage binds /nix/store but not this repo, so a result
        # symlink out here is invisible in there — the first version of this documented `./result` and
        # it failed with "No such file or directory".
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

      # The node's login shell is bash and zsh is not installed there either (verified:
      # `passwd … shell=/run/current-system/sw/bin/bash`, `zsh` not on PATH) — the same position as a
      # cage, so the same handoff. home-manager supplies zsh in the user profile; bash execs it for
      # interactive sessions only, leaving scripts and `ssh … <command>` on bash.
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
