{ lib, ... }: {

  home.activation = {
    iterm2Settings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "Setting up iTerm2 color scheme..."
      
      # Create necessary directories
      run mkdir -p $HOME/Library/Application\ Support/iTerm2/DynamicProfiles
      
      # Import the profile
      run cp -f "${./profiles.json}" \
        "$HOME/Library/Application Support/iTerm2/DynamicProfiles/happy-gopher.json"

      # Set profile as default using defaults command
      run /usr/bin/defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "7CF39BB4-4F21-4FB8-ACD5-3056C304A2C5"

      # Reload iTerm2 settings if it's running
      if /usr/bin/pgrep "iTerm2" > /dev/null; then
        #run killall "iTerm2"
        verboseEcho "iTerm2 is running, please reload manually"
      fi
    '';
  };
}
