{ lib, ... }: {
  home.activation = {
    terminalSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "Setting up Terminal.app profile..."
      
      # Import the profile
      run /usr/bin/plutil -replace "Window Settings.Happy Gopher" \
        -xml "$(cat ${./HappyGopher.plist.xml})" \
        ~/Library/Preferences/com.apple.Terminal.plist
        
      # Set as default
      run /usr/bin/defaults write com.apple.Terminal "Default Window Settings" -string "Happy Gopher"
      run /usr/bin/defaults write com.apple.Terminal "Startup Window Settings" -string "Happy Gopher"

      # Kill Terminal.app to apply changes
      run /usr/bin/killall Terminal || true
    '';
  };
}
