{ config, lib, pkgs, ... }: {
  system.activationScripts.systemSettings.text = ''
    echo "Configuring macOS system settings..."
    
    # Global UI/UX Settings 
    $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain AppleShowScrollBars -string "Always"
    $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
    
    # Keyboard Settings
    $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain KeyRepeat -int 1
    $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain InitialKeyRepeat -int 10
    
    # Text Input Settings
    $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
    $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
    $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
    $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    $DRY_RUN_CMD /usr/bin/defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
    
    # Dock Settings
    $DRY_RUN_CMD /usr/bin/defaults write com.apple.dock autohide -bool false
    $DRY_RUN_CMD /usr/bin/defaults write com.apple.dock mru-spaces -bool false
    $DRY_RUN_CMD /usr/bin/defaults write com.apple.dock autohide-delay -float 0
    $DRY_RUN_CMD /usr/bin/defaults write com.apple.dock autohide-time-modifier -float 0
    $DRY_RUN_CMD /usr/bin/defaults write com.apple.dock show-recents -bool false
    $DRY_RUN_CMD /usr/bin/defaults write com.apple.dock show-recents-automatically -bool false

    # Kill Dock to apply changes
    $DRY_RUN_CMD /usr/bin/killall Dock
  '';
}
