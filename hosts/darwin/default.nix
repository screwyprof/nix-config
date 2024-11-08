{ pkgs, config, ... }: {
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

    # Create symlink for Cursor's rgArm
    mkdir -p "/Users/parallels/.cursor-server/cli/servers/Stable-b1e87884330fc271d5eb589e368c35f14e76dec0/server/node_modules/@vscode/ripgrep/bin"
    ln -sf ${pkgs.ripgrep}/bin/rg "/Users/parallels/.cursor-server/cli/servers/Stable-b1e87884330fc271d5eb589e368c35f14e76dec0/server/node_modules/@vscode/ripgrep/bin/rgArm"
  '';

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
    trusted-users = [ "root" "@admin" ];
    download-buffer-size = 100000000;
  };

  # Create /etc/zshrc that loads the nix-darwin environment
  programs.zsh.enable = true;

  # Fonts
  fonts = {
    packages = with pkgs; [
      (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" ]; })
    ];
  };

  # Add the activation script for proper macOS application symlinks
  system.activationScripts.applications.text = let
    env = pkgs.buildEnv {
      name = "system-applications";
      paths = config.environment.systemPackages;
      pathsToLink = [ "/Applications" ];
      ignoreCollisions = true;
    };
    
    createLauncherScript = pkgs.writeShellScript "create-launcher" ''
      set -e  # Exit on error
      
      source_app="$1"
      app_name=$(basename "$source_app" .app)
      target="/Applications/Nix Apps/$app_name.app"
      temp_app="/tmp/$app_name.app"
      
      # Create temporary applescript
      cat > launcher.applescript << EOF
      try
          tell application "Finder"
              open POSIX file "$source_app"
          end tell
      on error errMsg
          display dialog "Error launching $app_name: " & errMsg buttons {"OK"} with icon stop
      end try
EOF
      
      # Compile to temporary location
      osacompile -o "$temp_app" launcher.applescript
      
      # Move to final location
      rm -rf "$target"
      mv "$temp_app" "$target"
      
      # Copy the icon
      icon_source="$source_app/Contents/Resources/"
      icon_dest="$target/Contents/Resources/applet.icns"
      if [ -d "$icon_source" ]; then
        icon_file=$(ls "$icon_source"/*.icns 2>/dev/null | head -n 1)
        if [ -n "$icon_file" ]; then
          cp "$icon_file" "$icon_dest"
        fi
      fi
      
      rm launcher.applescript
    '';
  in pkgs.lib.mkForce ''
    echo "setting up /Applications..." >&2
    rm -rf "/Applications/Nix Apps"
    mkdir -p "/Applications/Nix Apps"
    
    for pkg in ${toString config.environment.systemPackages}; do
      if [ -d "$pkg/Applications" ]; then
        for app in "$pkg/Applications/"*.app; do
          ${createLauncherScript} "$app"
        done
      fi
    done
  '';

  environment.systemPackages = with pkgs; [
    ripgrep
  ];
} 