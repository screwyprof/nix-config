{ config, lib, pkgs, ... }: {
  system.activationScripts.finderSettings.text = ''
    echo "Setting up Finder configuration..."
    
    # ===== Finder Settings =====
    
    # Desktop Icons
    /usr/bin/defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
    /usr/bin/defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
    /usr/bin/defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true
    /usr/bin/defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
    
    # Window Behavior
    /usr/bin/defaults write com.apple.finder NewWindowTarget -string "PfDe"
    /usr/bin/defaults write com.apple.finder NewWindowTargetPath -string "file:///Users/parallels"
    
    # View Options
    /usr/bin/defaults write com.apple.finder _FXSortFoldersFirst -bool true
    /usr/bin/defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
    /usr/bin/defaults write com.apple.finder ShowPathbar -bool true
    /usr/bin/defaults write com.apple.finder ShowStatusBar -bool true
    /usr/bin/defaults write com.apple.finder AppleShowAllFiles true
    
    # Search
    /usr/bin/defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
    
    # Warnings
    /usr/bin/defaults write com.apple.finder WarnOnEmptyTrash -bool false
    /usr/bin/defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
    
    # File Info
    /usr/bin/defaults write com.apple.finder FXInfoPanesExpanded -dict \
      General -bool true \
      OpenWith -bool true \
      Privileges -bool true

    # ===== Finder Sidebar Configuration =====
    echo "Configuring Finder sidebar..."
    
    # Remove existing items
    ${pkgs.mysides}/bin/mysides remove Recents || true
    ${pkgs.mysides}/bin/mysides remove Home || true
    ${pkgs.mysides}/bin/mysides remove Applications || true
    ${pkgs.mysides}/bin/mysides remove Desktop || true
    ${pkgs.mysides}/bin/mysides remove Documents || true
    ${pkgs.mysides}/bin/mysides remove Downloads || true
    ${pkgs.mysides}/bin/mysides remove "Hard Drive" || true
    
    # Add favorites in desired order
    ${pkgs.mysides}/bin/mysides add Recents "file:///System/Library/CoreServices/Finder.app/Contents/Resources/MyLibraries/myDocuments.cannedSearch/"
    ${pkgs.mysides}/bin/mysides add Home file://${config.home.homeDirectory}/
    ${pkgs.mysides}/bin/mysides add Applications file:///Applications/
    ${pkgs.mysides}/bin/mysides add Desktop file://${config.home.homeDirectory}/Desktop/
    ${pkgs.mysides}/bin/mysides add Documents file://${config.home.homeDirectory}/Documents/
    ${pkgs.mysides}/bin/mysides add Downloads file://${config.home.homeDirectory}/Downloads/
    ${pkgs.mysides}/bin/mysides add "Hard Drive" file:///

    # Make Library folder visible
    /usr/bin/chflags nohidden "${config.home.homeDirectory}/Library"
    /usr/bin/xattr -d com.apple.FinderInfo "${config.home.homeDirectory}/Library" 2>/dev/null || true
    /usr/bin/sudo /usr/bin/chflags nohidden /Volumes

    # Restart Finder to apply changes
    /usr/bin/killall Finder
  '';
}
