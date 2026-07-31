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
    { pkgs, ... }:
    let
      b = config.flake.lib.vscode.bundles pkgs;
    in
    {
      imports = with config.flake.modules.homeManager; [
        happygopher-identity
        dev-direnv
        dev-git
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
