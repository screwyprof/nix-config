{ pkgs, ... }: {
  home.sessionVariables = {
    VISUAL = "code";
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    mutableExtensionsDir = false;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;

    # Nix vscode extensions
    extensions = with pkgs.vscode-extensions; [
      # Theme and UI
      dracula-theme.theme-dracula
      pkief.material-icon-theme # File icons
      pkief.material-product-icons # UI icons
      usernamehw.errorlens # Inline error display

      # Language Support
      bbenoist.nix # Nix language
      golang.go # Go language
      rust-lang.rust-analyzer # Rust language (commented out)
      tamasfe.even-better-toml # TOML support

      # Development Tools
      fill-labs.dependi # Dependency management
      eamodio.gitlens # Git integration
      ms-azuretools.vscode-docker # Docker support
      formulahendry.auto-close-tag # HTML/XML tag closing
      ms-vscode.makefile-tools # Makefile support
      ms-vscode.live-server # Live server

      # Testing and Debugging
      vadimcn.vscode-lldb # LLDB debugger (cause warnings in settings.json)
      ms-vscode.test-adapter-converter # Test adapter support
      hbenl.vscode-test-explorer # Test explorer UI

      # Python Support
      ms-python.python # Python language support
      ms-python.vscode-pylance # Pylance language server

      # Remote Development
      ms-vscode-remote.remote-ssh # Remote SSH support
    ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      # Coverage Tools
      {
        name = "vscode-coverage-gutters";
        publisher = "ryanluker";
        version = "2.12.0";
        sha256 = "sha256-Dkc/Wqc122fV1r6IUyHOtuRdpbWHL3elAhfxHcY6xtM";
      }

      # Rust Tools
      {
        name = "rust-test-lens";
        publisher = "hdevalke";
        version = "1.0.0";
        sha256 = "faSBpgFIyqA9F03ghizTyFaB+XOwA1pNrStQlLTV9Pk=";
      }
      {
        name = "rust-doc-viewer";
        publisher = "jscearcy";
        version = "4.2.0";
        sha256 = "x1pmrw8wYHWyNIJqVdoh+vasbHDG/A4m8vDZU0DnPzo=";
      }
      {
        name = "vscode-rust-test-adapter";
        publisher = "swellaby";
        version = "0.11.0";
        sha256 = "IgfcIRF54JXm9l2vVjf7lFJOVSI0CDgDjQT+Hw6FO4Q=";
      }
    ];

    userSettings = {
      # Language-specific settings
      "[go]" = {
        "editor.codeActionsOnSave" = {
          "source.organizeImports" = "explicit";
        };
        "editor.formatOnSave" = true;
        "editor.snippetSuggestions" = "none";
      };

      "[python]" = {
        "editor.codeActionsOnSave" = {
          "source.organizeImports" = "explicit";
        };
        "editor.defaultFormatter" = "ms-python.python";
        "editor.formatOnSave" = true;
      };
      "python.defaultInterpreterPath" = "${pkgs.python312}/bin/python3";

      "[rust]" = {
        "editor.defaultFormatter" = "rust-lang.rust-analyzer";
        "editor.formatOnSave" = true;
        "editor.inlayHints.enabled" = "onUnlessPressed";
      };

      # Font settings
      "editor.fontFamily" = "'MesloLGMDZ Nerd Font', 'JetBrainsMono NF', 'FiraCode Nerd Font', monospace";
      "editor.fontLigatures" = true;
      "editor.fontSize" = 20;
      "editor.lineHeight" = 30;
      "editor.inlayHints.enabled" = "onUnlessPressed";
      "editor.inlineSuggest.enabled" = true;
      "chat.editor.fontFamily" = "'MesloLGMDZ Nerd Font', 'JetBrainsMono NF', 'FiraCode Nerd Font', monospace";
      "debug.console.fontFamily" = "'MesloLGMDZ Nerd Font','JetBrainsMono NF', 'FiraCode Nerd Font', monospace";
      "debug.console.fontSize" = 20;
      "terminal.integrated.fontFamily" = "'MesloLGMDZ Nerd Font', 'JetBrainsMono NF', 'FiraCode Nerd Font', monospace";
      "terminal.integrated.fontSize" = 20;

      # Update settings
      "extensions.autoCheckUpdates" = false;
      "update.mode" = "none";

      # File settings
      "files.associations" = {
        "*.rs" = "rust";
      };
      "json.schemaDownload.enable" = false;
      "window.openFilesInNewWindow" = "on";
      "window.zoomLevel" = 1;

      # Go settings
      "go.lintTool" = "golangci-lint";
      "go.testOnSave" = false;
      "go.toolsManagement.autoUpdate" = false;
      "go.useLanguageServer" = true;
      "go.testFlags" = [ "-v" ];
      "go.coverOnSave" = false;
      "go.coverOnSingleTest" = true;
      "go.coverOnSingleTestFile" = true;
      "go.delveConfig" = {
        "debugAdapter" = "dlv-dap";
        "showGlobalVariables" = true;
      };
      "go.coverageDecorator" = {
        "type" = "highlight";
        "coveredHighlightColor" = "rgba(64,128,128,0.2)";
        "uncoveredHighlightColor" = "rgba(128,64,64,0.2)";
        "coveredBorderColor" = "rgba(64,128,128,0.4)";
        "uncoveredBorderColor" = "rgba(128,64,64,0.4)";
      };

      # LLDB settings
      "lldb.commandCompletions" = true;
      "lldb.evaluateForHovers" = true;
      "lldb.launch.terminal" = "integrated";
      "lldb.suppressMissingSourceFiles" = true;

      # Theme and icon settings
      "material-icon-theme.activeIconPack" = "nest";
      "material-icon-theme.files.color" = "#42a5f5";
      "material-icon-theme.folders.color" = "#6bc1ff";
      "material-icon-theme.hidesExplorerArrows" = true;
      "workbench.colorTheme" = "Dracula";
      "workbench.iconTheme" = "material-icon-theme";
      "workbench.preferredDarkColorTheme" = "Dracula";
      "workbench.productIconTheme" = "material-product-icons";

      # Remote settings
      "remote.SSH.configFile" = "~/.ssh/config";

      # Test Explorer Settings
      "testExplorer.codeLens" = true;
      "testExplorer.gutterDecoration" = true;
      "testExplorer.onStart" = "retire";

      # Coverage Settings
      "coverage-gutters.coverageFileNames" = [
        "target/coverage/lcov.info"
      ];
      "coverage-gutters.showGutterCoverage" = true;
      "coverage-gutters.showLineCoverage" = true;
      "coverage-gutters.showRulerCoverage" = true;
      "coverage-gutters.highlightdark" = "rgba(64,128,64,0.4)";

      # Rust analyzer settings
      "rust-analyzer.cargo.features" = "all";
      "rust-analyzer.check.command" = "clippy";
      "rust-analyzer.check.extraArgs" = [ ];
      "rust-analyzer.completion.autoself.enable" = true;
      "rust-analyzer.files.excludeDirs" = [
        "**/.git/**"
        "**/target/**"
      ];
      "rust-analyzer.hover.actions.enable" = true;
      "rust-analyzer.inlayHints.parameterHints.enable" = true;
      "rust-analyzer.inlayHints.renderColons" = true;
      "rust-analyzer.inlayHints.typeHints.enable" = true;
      "rust-analyzer.lens.enable" = true;
      "rust-analyzer.lens.run.enable" = true;
      "rust-analyzer.lens.implementations.enable" = true;
      "rust-analyzer.lens.references.adt.enable" = true;
      "rust-analyzer.lens.references.method.enable" = true;
      "rust-analyzer.lens.references.trait.enable" = true;

      # Terminal settings
      "terminal.integrated.defaultProfile.osx" = "zsh";
      "terminal.integrated.profiles.osx" = {
        "zsh" = {
          "path" = "/etc/profiles/per-user/happygopher/bin/zsh";
        };
      };

      # Workbench color customizations
      "workbench.colorCustomizations" = {
        "terminal.foreground" = "#e9e9f4";
        "terminal.background" = "#21222C";
        "terminal.ansiBlack" = "#282A36";
        "terminal.ansiBlue" = "#BD93F9";
        "terminal.ansiBrightBlack" = "#3a3c4e";
        "terminal.ansiBrightBlue" = "#D6ACFF";
        "terminal.ansiBrightCyan" = "#A4FFFF";
        "terminal.ansiBrightGreen" = "#69FF94";
        "terminal.ansiBrightPurple" = "#FF92DF";
        "terminal.ansiBrightRed" = "#FF6E6E";
        "terminal.ansiBrightWhite" = "#FFFFFF";
        "terminal.ansiBrightYellow" = "#FFFFA5";
        "terminal.ansiCyan" = "#8BE9FD";
        "terminal.ansiGreen" = "#50FA7B";
        "terminal.ansiPurple" = "#FF79C6";
        "terminal.ansiRed" = "#FF5555";
        "terminal.ansiWhite" = "#F8F8F2";
        "terminal.ansiYellow" = "#F1FA8C";
      };
    };
  };
}
