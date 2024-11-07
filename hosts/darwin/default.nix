{ pkgs, ... }: {
  # Add state version
  system.stateVersion = 5;

  imports = [
    ../common/default.nix  # Import common system configuration
  ];

  # Darwin-specific configurations
  system.activationScripts.postActivation.text = ''
    # Install Command Line Tools
    if ! /usr/bin/xcode-select -p >/dev/null 2>&1; then
      touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
      PROD=$(/usr/sbin/softwareupdate -l | grep "\*.*Command Line" | tail -n 1 | sed 's/^[^C]* //')
      /usr/sbin/softwareupdate -i "$PROD" --verbose
      rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    fi
  '';

  # System configuration
  system = {
    defaults = {
      dock = {
        autohide = true;
        mru-spaces = false;
        minimize-to-application = true;
      };
      
      finder = {
        AppleShowAllExtensions = true;
        FXEnableExtensionChangeWarning = false;
      };
      
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
      };
    };
  };

  # System-wide environment variables
  environment = {
    pathsToLink = [ "/Applications" ];
  };

  # Enable necessary services
  services = {
    nix-daemon.enable = true;
  };

  # Nix configuration
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    build-users-group = "nixbld";
    trusted-users = [ "root" "@admin" "parallels" ];
    download-buffer-size = 100000000;
  };

  # Create /etc/zshrc that loads the nix-darwin environment
  programs.zsh.enable = true;

  # Fonts
  fonts = {
    packages = with pkgs; [
      (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
    ];
  };
} 