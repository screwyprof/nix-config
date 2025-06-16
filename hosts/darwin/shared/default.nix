{ self, systemAdmin, ... }:
{
  imports = [
    ./spotlight.nix
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
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      build-users-group = "nixbld";
      trusted-users = [ "root" systemAdmin.username ];
      download-buffer-size = 100000000;
      warn-dirty = false;
    };

    gc = {
      automatic = true;
      interval = { Weekday = 0; Hour = 0; Minute = 0; };
      options = "--delete-older-than 7d";
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
      "cursor"
      "firefox"
      "google-chrome"
      "iterm2"
      "jetbrains-toolbox"
      "tableplus"
      "telegram"
      "windsurf"
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
