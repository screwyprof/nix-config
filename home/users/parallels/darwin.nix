{ config, lib, pkgs, ... }: {
  home.homeDirectory = lib.mkForce "/Users/parallels";

  home.activation = {
    setDefaults = lib.hm.dag.entryAfter ["writeBoundary"] ''
      echo "Setting up macOS defaults..."
      
      # ===== Finder Settings =====
      
      # Desktop Icons
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

      # ===== Global Settings =====
      
      # UI Behavior
      $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain AppleShowScrollBars -string "Always"
      $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
      
      # Keyboard
      $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain KeyRepeat -int 1
      $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain InitialKeyRepeat -int 10
      
      # Text Input
      $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
      $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
      $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
      $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
      $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
      
      # ===== Dock Settings =====
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.dock autohide -bool false
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.dock mru-spaces -bool false
      
      # ===== System Settings =====
      
      # Security
      $DRY_RUN_CMD /usr/bin/defaults write com.apple.LaunchServices LSQuarantine -bool false
      
      # Visibility
      $DRY_RUN_CMD /usr/bin/chflags nohidden "${config.home.homeDirectory}/Library"
      $DRY_RUN_CMD /usr/bin/xattr -d com.apple.FinderInfo "${config.home.homeDirectory}/Library" 2>/dev/null || true
      $DRY_RUN_CMD /usr/bin/sudo /usr/bin/chflags nohidden /Volumes
      
      # ===== Finder Sidebar Configuration =====
      echo "Configuring Finder sidebar..."
      
      # Remove existing items
      $DRY_RUN_CMD ${pkgs.mysides}/bin/mysides remove Recents || true
      $DRY_RUN_CMD ${pkgs.mysides}/bin/mysides remove Home || true
      $DRY_RUN_CMD ${pkgs.mysides}/bin/mysides remove Applications || true
      $DRY_RUN_CMD ${pkgs.mysides}/bin/mysides remove Desktop || true
      $DRY_RUN_CMD ${pkgs.mysides}/bin/mysides remove Documents || true
      $DRY_RUN_CMD ${pkgs.mysides}/bin/mysides remove Downloads || true
      $DRY_RUN_CMD ${pkgs.mysides}/bin/mysides remove "Hard Drive" || true
      
      # Add favorites in desired order
      $DRY_RUN_CMD ${pkgs.mysides}/bin/mysides add Recents "file:///System/Library/CoreServices/Finder.app/Contents/Resources/MyLibraries/myDocuments.cannedSearch/"
      $DRY_RUN_CMD ${pkgs.mysides}/bin/mysides add Home file://${config.home.homeDirectory}/
      $DRY_RUN_CMD ${pkgs.mysides}/bin/mysides add Applications file:///Applications/
      $DRY_RUN_CMD ${pkgs.mysides}/bin/mysides add Desktop file://${config.home.homeDirectory}/Desktop/
      $DRY_RUN_CMD ${pkgs.mysides}/bin/mysides add Documents file://${config.home.homeDirectory}/Documents/
      $DRY_RUN_CMD ${pkgs.mysides}/bin/mysides add Downloads file://${config.home.homeDirectory}/Downloads/
      $DRY_RUN_CMD ${pkgs.mysides}/bin/mysides add "Hard Drive" file:///
      
      # ===== Restart UI =====
      $DRY_RUN_CMD /usr/bin/killall Finder
      $DRY_RUN_CMD /usr/bin/killall Dock
    '';
  };

  # Required packages
  home.packages = with pkgs; [
    mysides
  ];
}