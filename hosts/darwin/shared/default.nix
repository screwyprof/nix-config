{ self, lib, pkgs, systemAdmin, config, ... }:
{
  imports = [
    ./spotlight.nix
  ];

  # Remove old default Nix profile but keep nix-darwin defaults
  environment.profiles = lib.mkForce [
    "/run/current-system/sw"
    "/etc/profiles/per-user/$USER" # Home-manager user packages (dynamically resolved)
    "$HOME/.nix-profile"
  ];

  # System configuration
  system = {
    # Add state version
    stateVersion = 5;

    # Set Git commit hash for darwin-version
    configurationRevision = self.rev or self.dirtyRev or null;

    # Set system defaults
    # defaults = {
    #   dock.autohide = true;
    #   finder = {
    #     AppleShowAllExtensions = true;
    #     FXPreferredViewStyle = "clmv";  # Column view
    #   };
    #   screencapture.location = "~/Pictures/screenshots";
    # };
  };

  # Enable TouchID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # Nix configuration
  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      build-users-group = "nixbld";
      trusted-users = [ "root" systemAdmin.username ];
      download-buffer-size = 100000000;
      warn-dirty = false;

      # Performance optimizations
      max-jobs = "auto"; # Use all available cores efficiently
      build-timeout = 3600; # 1 hour timeout for builds
      connect-timeout = 5; # 5 second connection timeout

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

      # Debugging and development
      # keep-outputs = true; # Keep build outputs for debugging
      # keep-derivations = true; # Keep derivations for nix-shell
    };

    # ────────────────────────────────────────────────
    # Have root’s Nix use XDG for profiles, so system GC will
    # see ~/.local/state/nix/profiles/... (incl. HM generations)
    extraOptions = ''
      use-xdg-base-directories = true
    '';

    # Enhanced garbage collection strategy
    gc = {
      automatic = true;
      interval = { Weekday = 0; Hour = 0; Minute = 0; };
      options = "--delete-older-than 30d --max-freed 8G";
    };

    # Optimise nix store automatically
    optimise = {
      automatic = true;
    };

  };

  # Common Homebrew configuration for all macOS hosts
  homebrew = {
    enable = true;

    global = {
      autoUpdate = true; # Enable global auto-update to prevent HOMEBREW_NO_AUTO_UPDATE
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
      "1password"
      "bitwarden"
      "crossover"
      "cursor"
      "firefox"
      "google-chrome"
      "iterm2"
      "jetbrains-toolbox"
      "parallels"
      "tableplus"
      "telegram"
      "zoom"
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
}
