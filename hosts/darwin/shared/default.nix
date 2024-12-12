{
  imports = [
    ./spotlight.nix
  ];

  # System configuration
  system = {
    # Add state version
    stateVersion = 5;

    # Set system defaults
    defaults = {
      # Disable automatic capitalization as it's annoying when typing code
      #NSGlobalDomain.NSAutomaticCapitalizationEnabled = false;
    };

    # Darwin-specific configurations
    activationScripts.postActivation.text = ''
      # Install Command Line Tools
      if ! /usr/bin/xcode-select -p >/dev/null 2>&1; then
        touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
        PROD=$(/usr/sbin/softwareupdate -l | grep "\*.*Command Line" | tail -n 1 | sed 's/^[^C]* //')
        /usr/sbin/softwareupdate -i "$PROD" --verbose
        rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
      fi
    '';
  };

  # Enable necessary services
  services = {
    nix-daemon.enable = true;
  };

  # Nix configuration
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      build-users-group = "nixbld";
      trusted-users = [ "root" "happygopher" ];
      download-buffer-size = 100000000;
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
    onActivation = {
      autoUpdate = false;
      cleanup = "zap";
      upgrade = false;
    };

    caskArgs = {
      appdir = "~/Applications";
      require_sha = true;
    };

    casks = [
      "1password"
      "bitwarden"
      "cursor"
      "firefox"
      "iterm2"
      "jetbrains-toolbox"
      "tableplus"
      "telegram"
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
