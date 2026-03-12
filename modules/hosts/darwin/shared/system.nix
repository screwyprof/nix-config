{
  inputs,
  self,
  ...
}:
let
  systemAdmin = "happygopher";
in
{
  flake.modules.darwin.system =
    {
      lib,
      pkgs,
      ...
    }:
    {
      # Secrets management
      imports = [
        inputs.sops-nix.darwinModules.sops
        inputs.nix-homebrew.darwinModules.nix-homebrew
      ];
      # Nixpkgs configuration
      nixpkgs.overlays = [ self.overlays.default ];
      nixpkgs.config.allowUnfree = true;

      # Exclude /nix/var/nix/profiles/default from PATH — it contains a stale
      # bootstrap Nix that conflicts with the declaratively managed nix from pkgs.nix
      environment.profiles = lib.mkForce [
        "/run/current-system/sw"
        "/etc/profiles/per-user/$USER" # Home-manager user packages
      ];

      # System configuration
      system = {
        primaryUser = systemAdmin;
        stateVersion = 5;
        configurationRevision = self.rev or self.dirtyRev or null;
      };

      # Enable TouchID for sudo
      security.pam.services.sudo_local.touchIdAuth = true;

      # Nix configuration
      nix = {
        package = pkgs.nix;
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          build-users-group = "nixbld";
          trusted-users = [
            "root"
            systemAdmin
          ];
          download-buffer-size = 100000000;
          warn-dirty = false;

          # Performance optimizations
          max-jobs = "auto";
          build-timeout = 3600;
          connect-timeout = 5;

          # Additional substitutes for faster builds
          substituters = [
            "https://cache.nixos.org/"
            "https://nix-community.cachix.org"
            "https://devenv.cachix.org"
            "https://claude-code.cachix.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
            "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
          ];
        };

        extraOptions = ''
          use-xdg-base-directories = true
        '';

        gc = {
          automatic = true;
          interval = {
            Weekday = 0;
            Hour = 0;
            Minute = 0;
          };
          options = "--delete-older-than 30d --max-freed 8G";
        };

        optimise = {
          automatic = true;
        };
      };

      # Prune old system profile generations (nix.gc only handles user profiles)
      launchd.daemons.nix-gc-system-profiles = {
        command = "/bin/sh -c '/nix/var/nix/profiles/system/sw/bin/nix-env --delete-generations +3 --profile /nix/var/nix/profiles/system'";
        serviceConfig = {
          RunAtLoad = false;
          StartCalendarInterval = [
            {
              Weekday = 0;
              Hour = 23;
              Minute = 55;
            }
          ];
        };
      };

      # Nix-homebrew integration
      nix-homebrew = {
        enable = true;
        mutableTaps = false;
        user = lib.mkDefault systemAdmin;
        taps = {
          "homebrew/core" = inputs.homebrew-core;
          "homebrew/cask" = inputs.homebrew-cask;
          "homebrew/bundle" = inputs.homebrew-bundle;
        };
      };

      # Common Homebrew configuration for all macOS hosts
      homebrew = {
        enable = true;

        global = {
          autoUpdate = true;
        };

        onActivation = {
          cleanup = "zap";
          upgrade = true;
        };

        caskArgs = {
          appdir = "~/Applications";
          require_sha = false;
        };

        casks = [
          "bitwarden"
          "crossover"
          "firefox"
          "iterm2"
          "jetbrains-toolbox"
          "parallels"
          "tableplus"
        ];

        brews = [
          "mas"
        ];

        masApps = {
          "Bear" = 1091189122;
          "Noir" = 1592917505;
          "AdGuard for Safari" = 1440147259;
        };
      };
    };
}
