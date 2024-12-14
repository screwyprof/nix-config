{ config, lib, ... }: {
  home.activation = {
    userPreferences = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      verboseEcho "Configuring macOS preferences..."
      
      # ===== Keyboard Settings =====
      run /usr/bin/defaults write NSGlobalDomain KeyRepeat -int 1
      run /usr/bin/defaults write NSGlobalDomain InitialKeyRepeat -int 10
      run /usr/bin/defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
      
      # ===== Text Input Settings =====
      run /usr/bin/defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
      run /usr/bin/defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
      run /usr/bin/defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
      run /usr/bin/defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
      run /usr/bin/defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
      
      # ===== Dock Settings =====
      run /usr/bin/defaults write com.apple.dock autohide -bool true
      run /usr/bin/defaults write com.apple.dock mru-spaces -bool false
      
      # ===== Finder Settings =====
      run /usr/bin/defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
      run /usr/bin/defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
      run /usr/bin/defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true
      run /usr/bin/defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
      
      # Window Behavior
      run /usr/bin/defaults write com.apple.finder NewWindowTarget -string "PfDe"
      run /usr/bin/defaults write com.apple.finder NewWindowTargetPath -string "file://${config.home.homeDirectory}"
      
      # View Options
      run /usr/bin/defaults write com.apple.finder _FXSortFoldersFirst -bool true
      run /usr/bin/defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
      run /usr/bin/defaults write com.apple.finder ShowPathbar -bool true
      run /usr/bin/defaults write com.apple.finder ShowStatusBar -bool true
      run /usr/bin/defaults write com.apple.finder AppleShowAllFiles true
      run /usr/bin/defaults write NSGlobalDomain AppleShowAllExtensions -bool true
      
      # Search
      run /usr/bin/defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
      
      # Warnings
      run /usr/bin/defaults write com.apple.finder WarnOnEmptyTrash -bool false
      run /usr/bin/defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
      
      # File Info
      run /usr/bin/defaults write com.apple.finder FXInfoPanesExpanded -dict \
        General -bool true \
        OpenWith -bool true \
        Privileges -bool true

      # Make Library folder visible
      run /usr/bin/chflags nohidden "${config.home.homeDirectory}/Library"
      run /usr/bin/xattr -d com.apple.FinderInfo "${config.home.homeDirectory}/Library" 2>/dev/null || true
      
      # ===== Security Settings =====
      run /usr/bin/defaults write com.apple.LaunchServices LSQuarantine -bool false

      # Enable iCloud Drive and sync settings
      #run /usr/bin/defaults write com.apple.finder FXICloudDriveEnabled -bool true
      #run /usr/bin/defaults write com.apple.finder FXICloudDriveDesktop -bool true
      #run /usr/bin/defaults write com.apple.finder FXICloudDriveDocuments -bool true
      
      # ===== Restart UI =====
      run /usr/bin/killall Dock || true
      run /usr/bin/killall Finder || true

      # Following line should allow us to avoid a logout/login cycle
      run /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';
  };
}
