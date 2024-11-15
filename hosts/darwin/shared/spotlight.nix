{ pkgs, config, ... }:
let
  createLauncherScript = pkgs.writeShellScript "create-launcher" ''
    set -e
    
    source_app="$1"
    target_dir="$2"
    app_name=$(basename "$source_app" .app)
    target="$target_dir/$app_name.app"
    temp_app="/tmp/$app_name.app"
    
    echo "Creating launcher for $app_name" >&2
    echo "Source: $source_app" >&2
    echo "Target: $target" >&2
    
    cat > launcher.applescript << EOF
    try
        tell application "Finder"
            open POSIX file "$source_app"
        end tell
    on error errMsg
        display dialog "Error launching $app_name: " & errMsg buttons {"OK"} with icon stop
    end try
    EOF
    
    osacompile -o "$temp_app" launcher.applescript
    rm -rf "$target"
    mv "$temp_app" "$target"
    
    icon_source="$source_app/Contents/Resources/"
    icon_dest="$target/Contents/Resources/applet.icns"
    if [ -d "$icon_source" ]; then
      icon_file=$(ls "$icon_source"/*.icns 2>/dev/null | head -n 1)
      if [ -n "$icon_file" ]; then
        cp "$icon_file" "$icon_dest"
      fi
    fi
    
    rm launcher.applescript
    echo "launcher for $app_name created" >&2
  '';

  hmUsers = builtins.attrNames config.home-manager.users;

  userScripts = map
    (username: ''
      echo "Processing user: ${username}" >&2
      user_home="/Users/${username}"
      hm_apps_dir="$user_home/Applications/Home Manager Apps"
      nix_apps_dir="$user_home/Applications/Nix Apps"

      if [ -d "$hm_apps_dir" ]; then
        rm -rf "$nix_apps_dir"
        mkdir -p "$nix_apps_dir"
        
        for app in "$hm_apps_dir/"*.app; do
          if [ -L "$app" ]; then
            real_app=$(readlink "$app")
            if [ -n "$real_app" ] && [ -d "$real_app" ]; then
              ${createLauncherScript} "$real_app" "$nix_apps_dir"
            fi
          fi
        done
        chown -R "${username}:staff" "$nix_apps_dir"
      fi
    '')
    hmUsers;
in
{
  system.activationScripts.applications.text = pkgs.lib.mkForce ''
    ${builtins.concatStringsSep "\n" userScripts}
  '';
}
