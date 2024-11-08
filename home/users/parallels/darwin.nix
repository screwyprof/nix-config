{ config, lib, pkgs, ... }: {
  home.homeDirectory = lib.mkForce "/Users/parallels";

  home.activation = {
    setDefaults = lib.hm.dag.entryAfter ["writeBoundary"] ''
      echo "Setting up macOS defaults..."
      
      # Finder Preferences - Desktop
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder ShowMountedServersOnDesktop -bool false
      
      # Finder View and Window Settings
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder WarnOnEmptyTrash -bool false
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder _FXSortFoldersFirst -bool true
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder NewWindowTarget -string "PfDe"
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder NewWindowTargetPath -string "file://${config.home.homeDirectory}"
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder AppleShowAllFiles true
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder ShowPathbar -bool true
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder ShowStatusBar -bool true
      
      # Global Domain Settings
      $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain AppleShowScrollBars -string "Always"
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.LaunchServices LSQuarantine -bool false

      # Disable automatic capitalization as it’s annoying when typing code
      $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

      # Disable smart dashes as they’re annoying when typing code
      $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

      # Disable automatic period substitution as it’s annoying when typing code
      $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

      # Disable smart quotes as they’re annoying when typing code
      $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

      # Disable auto-correct
      $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

      # Enable full keyboard access for all controls
      $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

      # Set a blazingly fast keyboard repeat rate
      $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain KeyRepeat -int 1
      $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain InitialKeyRepeat -int 10
      
      # Dock
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.dock autohide -bool false
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.dock mru-spaces -bool false

      # Show the ~/Library 
      $DRY_RUN_CMD /usr/bin/chflags nohidden "${config.home.homeDirectory}/Library"
      $DRY_RUN_CMD /usr/bin/xattr -d com.apple.FinderInfo "${config.home.homeDirectory}/Library" 2>/dev/null || true
  
      # Show the /Volumes folder
      $DRY_RUN_CMD /usr/bin/sudo /usr/bin/chflags nohidden /Volumes

      # Expand the following File Info panes:
      # “General”, “Open with”, and “Sharing & Permissions”
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder FXInfoPanesExpanded -dict \
	      General -bool true \
	      OpenWith -bool true \
	      Privileges -bool true
      
      # Restart UI elements
      $DRY_RUN_CMD /usr/bin/killall Finder
      $DRY_RUN_CMD /usr/bin/killall Dock

      # Finder Sidebar Configuration
      echo "Configuring Finder sidebar..."

      # Before changes
      echo "Dumping initial states..."
      $DRY_RUN_CMD /usr/libexec/PlistBuddy -x -c "Print" "/Users/parallels/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.FavoriteVolumes.sfl3" > volumes.before.xml
      $DRY_RUN_CMD /usr/libexec/PlistBuddy -x -c "Print" "/Users/parallels/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.FavoriteItems.sfl3" > items.before.xml

      echo "Current sidebar items:"
      $DRY_RUN_CMD ${pkgs.finder-sidebar-editor}/bin/finder-sidebar-editor --list || true
      
      # Remove existing items using mysides
      echo "Removing existing favorites with mysides..."
      $DRY_RUN_CMD ${pkgs.mysides}/bin/mysides remove "Recents" || true
      $DRY_RUN_CMD ${pkgs.mysides}/bin/mysides remove "Applications" || true
      $DRY_RUN_CMD ${pkgs.mysides}/bin/mysides remove "Desktop" || true
      $DRY_RUN_CMD ${pkgs.mysides}/bin/mysides remove "Documents" || true
      $DRY_RUN_CMD ${pkgs.mysides}/bin/mysides remove "Downloads" || true
      $DRY_RUN_CMD ${pkgs.mysides}/bin/mysides remove "Home" || true
      
      # Remove volumes using finder-sidebar-editor
      echo "Removing existing volumes..."
      $DRY_RUN_CMD ${pkgs.finder-sidebar-editor}/bin/finder-sidebar-editor --remove "/" --volume || true
      #$DRY_RUN_CMD ${pkgs.finder-sidebar-editor}/bin/finder-sidebar-editor --remove "/System/Volumes/Data" --volume || true
      
      # Add favorites using mysides
      echo "Adding favorites with mysides..."
      $DRY_RUN_CMD ${pkgs.mysides}/bin/mysides add "Recents" "file:///System/Library/CoreServices/Finder.app/Contents/Resources/MyLibraries/myDocuments.cannedSearch"
      $DRY_RUN_CMD ${pkgs.mysides}/bin/mysides add "Home" "file://${config.home.homeDirectory}"
      $DRY_RUN_CMD ${pkgs.mysides}/bin/mysides add "Applications" "file:///Applications"
      $DRY_RUN_CMD ${pkgs.mysides}/bin/mysides add "Desktop" "file://${config.home.homeDirectory}/Desktop"
      $DRY_RUN_CMD ${pkgs.mysides}/bin/mysides add "Documents" "file://${config.home.homeDirectory}/Documents"
      $DRY_RUN_CMD ${pkgs.mysides}/bin/mysides add "Downloads" "file://${config.home.homeDirectory}/Downloads"
      
      # Add volumes using finder-sidebar-editor
      echo "Adding volumes..."
      #$DRY_RUN_CMD ${pkgs.finder-sidebar-editor}/bin/finder-sidebar-editor --add "/" --name "Hard Drive"  || true
      
      echo "Final sidebar configuration:"
      $DRY_RUN_CMD ${pkgs.mysides}/bin/mysides list || true

      # After changes
      echo "Dumping final states..."
      $DRY_RUN_CMD /usr/libexec/PlistBuddy -x -c "Print" "/Users/parallels/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.FavoriteVolumes.sfl3" > volumes.after.xml
      $DRY_RUN_CMD /usr/libexec/PlistBuddy -x -c "Print" "/Users/parallels/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.FavoriteItems.sfl3" > items.after.xml

      # Compare
      echo "Comparing changes..."
      $DRY_RUN_CMD diff -u volumes.before.xml volumes.after.xml
      $DRY_RUN_CMD diff -u items.before.xml items.after.xml
    '';
  };

  # Make sure mysides is available
  home.packages = with pkgs; [
    mysides
    finder-sidebar-editor
  ];
}