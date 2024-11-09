{ config, lib, pkgs, ... }: {
  home.activation = {
    terminalSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
      echo "Setting up Terminal.app profile..."
      
      # Import the profile
      $DRY_RUN_CMD /usr/bin/plutil -replace "Window Settings.Happy Gopher" \
        -xml "$(cat ${./HappyGopher.plist.xml})" \
        ~/Library/Preferences/com.apple.Terminal.plist
        
      # Set as default
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.Terminal "Default Window Settings" -string "Happy Gopher"
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.Terminal "Startup Window Settings" -string "Happy Gopher"

      # Kill Terminal.app to apply changes
      $DRY_RUN_CMD /usr/bin/killall Terminal || true
    '';
  };
}
