{ config, lib, ... }: {
  targets.darwin.defaults = {
    # Global domain settings
    NSGlobalDomain = {
      # Keyboard
      KeyRepeat = 1;
      InitialKeyRepeat = 10;
      AppleKeyboardUIMode = 3;

      # Text Input
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
    };

    # Dock settings
    "com.apple.dock" = {
      autohide = true;
      "mru-spaces" = false;
    };

    # Finder settings
    "com.apple.finder" = {
      # Desktop icons
      ShowHardDrivesOnDesktop = true;
      ShowExternalHardDrivesOnDesktop = true;
      ShowRemovableMediaOnDesktop = true;
      ShowMountedServersOnDesktop = true;

      # Window behavior
      NewWindowTarget = "PfDe";
      NewWindowTargetPath = "file://${config.home.homeDirectory}";

      # View options
      _FXSortFoldersFirst = true;
      _FXShowPosixPathInTitle = true;
      ShowPathbar = true;
      ShowStatusBar = true;
      AppleShowAllFiles = true;

      # Search
      FXDefaultSearchScope = "SCcf";

      # Warnings
      WarnOnEmptyTrash = false;
      FXEnableExtensionChangeWarning = false;

      # File Info
      FXInfoPanesExpanded = {
        General = true;
        OpenWith = true;
        Privileges = true;
      };
    };

    # Security settings
    "com.apple.LaunchServices" = {
      LSQuarantine = false;
    };
  };

  # Activate settings without logout
  home.activation.reloadPreferences = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Reload preferences
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';
}
