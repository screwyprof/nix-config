{ config, lib, pkgs, ... }: {
  home.activation = {
    userPreferences = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "Configuring macOS preferences..."
      
      # ===== Keyboard Settings =====
      $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain KeyRepeat -int 1
      $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain InitialKeyRepeat -int 10
      $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
      
      # ===== Text Input Settings =====
      $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
      $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
      $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
      $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
      $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
      
      # ===== Dock Settings =====
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.dock autohide -bool false
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.dock mru-spaces -bool false
      
      # ===== Finder Settings =====
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
      
      # Window Behavior
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder NewWindowTarget -string "PfDe"
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder NewWindowTargetPath -string "file://${config.home.homeDirectory}"
      
      # View Options
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder _FXSortFoldersFirst -bool true
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder ShowPathbar -bool true
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder ShowStatusBar -bool true
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder AppleShowAllFiles true
      
      # Search
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
      
      # Warnings
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder WarnOnEmptyTrash -bool false
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
      
      # File Info
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.finder FXInfoPanesExpanded -dict \
        General -bool true \
        OpenWith -bool true \
        Privileges -bool true

      # Make Library folder visible
      $DRY_RUN_CMD /usr/bin/chflags nohidden "${config.home.homeDirectory}/Library"
      $DRY_RUN_CMD /usr/bin/xattr -d com.apple.FinderInfo "${config.home.homeDirectory}/Library" 2>/dev/null || true
      
      # ===== Security Settings =====
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.LaunchServices LSQuarantine -bool false
      
      # ===== Restart UI =====
      $DRY_RUN_CMD /usr/bin/killall Dock || true
      $DRY_RUN_CMD /usr/bin/killall Finder || true

      # Following line should allow us to avoid a logout/login cycle
      $DRY_RUN_CMD /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';
  };
}
