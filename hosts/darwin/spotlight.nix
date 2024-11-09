{ pkgs, config, lib, ... }:
let
  createLauncherScript = pkgs.writeShellScript "create-launcher" ''
    set -e  # Exit on error
    
    source_app="$1"
    target_dir="$2"
    app_name=$(basename "$source_app" .app)
    target="$target_dir/$app_name.app"
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
in {
  system.activationScripts.applications.text = pkgs.lib.mkForce ''
    # Constants
    SYSTEM_APPS_DIR="/Applications/Nix Apps"
    
    echo "setting up system-wide application launchers..." >&2
    rm -rf "$SYSTEM_APPS_DIR"
    mkdir -p "$SYSTEM_APPS_DIR"
    
    # Handle system-wide applications
    for pkg in ${toString config.environment.systemPackages}; do
      if [ -d "$pkg/Applications" ]; then
        for app in "$pkg/Applications/"*.app; do
          ${createLauncherScript} "$app" "$SYSTEM_APPS_DIR"
        done
      fi
    done

    # Handle Home Manager applications for all users
    for user in /Users/*; do
      username=$(basename "$user")
      user_apps_dir="$user/Applications"
      hm_apps_dir="$user_apps_dir/Home Manager Apps"
      nix_apps_dir="$user_apps_dir/Nix Apps"

      if [ -d "$hm_apps_dir" ]; then
        echo "setting up user application launchers for $username..." >&2
        rm -rf "$nix_apps_dir"
        mkdir -p "$nix_apps_dir"

        for app in "$hm_apps_dir/"*.app; do
          if [ -L "$app" ]; then  # Check if it's a symlink
            real_app=$(readlink "$app")
            if [ -n "$real_app" ] && [ -d "$real_app" ]; then
              ${createLauncherScript} "$real_app" "$nix_apps_dir"
            fi
          fi
        done
      fi
    done
  '';
} 