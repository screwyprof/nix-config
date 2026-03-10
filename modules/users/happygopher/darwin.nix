{
  flake.modules.homeManager.happygopher-darwin =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      home = {
        stateVersion = "24.11";

        file = {
          "Projects".source =
            config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Documents/Projects";
        };

        packages = with pkgs; [
          mysides
        ];

        activation = {
          # macOS preferences
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

            # ===== Restart UI =====
            run /usr/bin/killall Dock || true
            run /usr/bin/killall Finder || true

            # Following line should allow us to avoid a logout/login cycle
            run /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
          '';

          # Terminal.app profile
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
            verboseEcho "Terminal.app is running, please reload manually"
          '';

          # iTerm2 profile
          iterm2Settings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            echo "Setting up iTerm2 color scheme..."

            # Create necessary directories
            run mkdir -p $HOME/Library/Application\ Support/iTerm2/DynamicProfiles

            # Import the profile
            run cp -f "${./iterm2-profiles.json}" \
              "$HOME/Library/Application Support/iTerm2/DynamicProfiles/happy-gopher.json"

            # Set profile as default using defaults command
            run /usr/bin/defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "7CF39BB4-4F21-4FB8-ACD5-3056C304A2C5"

            # Reload iTerm2 settings if it's running
            if /usr/bin/pgrep "iTerm2" > /dev/null; then
              verboseEcho "iTerm2 is running, please reload manually"
            fi
          '';
        };
      };

      programs.git.settings.user = {
        name = "Happy Gopher";
        email = "max@happygopher.nl";
      };

      xdg.enable = true;
    };
}
