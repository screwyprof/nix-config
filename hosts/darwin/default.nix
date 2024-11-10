{ pkgs, config, ... }: {
  # Add state version
  system.stateVersion = 5;

  imports = [
    ./spotlight.nix
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

    # Create symlink for Cursor's rgArm
    mkdir -p "/Users/parallels/.cursor-server/cli/servers/Stable-b1e87884330fc271d5eb589e368c35f14e76dec0/server/node_modules/@vscode/ripgrep/bin"
    ln -sf ${pkgs.ripgrep}/bin/rg "/Users/parallels/.cursor-server/cli/servers/Stable-b1e87884330fc271d5eb589e368c35f14e76dec0/server/node_modules/@vscode/ripgrep/bin/rgArm"
  '';

  # Enable necessary services
  services = {
    nix-daemon.enable = true;
  };

  # Nix configuration
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    build-users-group = "nixbld";
    trusted-users = [ "root" "@admin" ];
    download-buffer-size = 100000000;
  };

  # Create /etc/zshrc that loads the nix-darwin environment
  programs.zsh.enable = true;

  # System-wide environment variables
  environment = {
    pathsToLink = [ "/Applications" ]; # links Home 
  };
}
