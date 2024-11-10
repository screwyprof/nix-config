{ config, pkgs, lib, ... }: {
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    mutableExtensionsDir = false;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;

    # Nix vscode extensions
    extensions = with pkgs.vscode-extensions; [
      # Theme and UI
      emroussel.atomize-atom-one-dark-theme  # Color theme
      pkief.material-icon-theme              # File icons
      usernamehw.errorlens                   # Inline error display

      # Language Support
      bbenoist.nix                           # Nix language
      golang.go                              # Go language
      #rust-lang.rust-analyzer               # Rust language (commented out)
      tamasfe.even-better-toml               # TOML support

      # Development Tools
      eamodio.gitlens                       # Git integration
      ms-azuretools.vscode-docker           # Docker support
      formulahendry.auto-close-tag          # HTML/XML tag closing
      ms-vscode.makefile-tools              # Makefile support

      # Testing and Debugging
      #vadimcn.vscode-lldb                  # LLDB debugger (cause warnings in settings.json)
      ms-vscode.test-adapter-converter      # Test adapter support
      hbenl.vscode-test-explorer            # Test explorer UI
    ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      # Additional Tools
      {
        name = "dependi";
        publisher = "fill-labs";
        version = "0.7.10";
        sha256 = "m8W21ztTmEOjDI1KCymeBgQzg9jdgKG9dCFp+U1D818=";
      }

      #Rust Tools
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
      # update settings\
      "update.mode" = "none";
      "extensions.autoCheckUpdates" = false;

      # theme settings
      "workbench.colorTheme" = "Atomize";

      # Editor settings
      "editor" = {
        "fontFamily" = "'JetBrainsMono NF', 'FiraCode Nerd Font', monospace";
        "fontLigatures" = true;
        "fontSize" = 20;
        "lineHeight" = 30;
      };

      # Terminal settings
      "terminal.integrated" = {
        "fontFamily" = "'JetBrainsMono NF', 'FiraCode Nerd Font', monospace";
        "fontSize" = 20;
      };

      # Language-specific settings
      "[go]" = {
        "editor.codeActionsOnSave" = {
          "source.organizeImports" = "explicit";
        };
        "editor.formatOnSave" = true;
        "editor.snippetSuggestions" = "none";
      };

      # Go settings
      "go" = {
        "coverOnSave" = false;
        "coverOnSingleTest" = true;
        "delveConfig" = {
          "debugAdapter" = "dlv-dap";
          "showGlobalVariables" = true;
        };
        "lintTool" = "golangci-lint";
        "testOnSave" = false;
        "toolsManagement.autoUpdate" = false;
        "useLanguageServer" = true;
      };

      # Go debugger settings
      "go.delveConfig" = {
        "debugAdapter" = "dlv-dap";
        "showGlobalVariables" = true;
      };

      # Debug settings
      "debug" = {
        "console" = {
          "fontFamily" = "'JetBrainsMono NF', 'FiraCode Nerd Font', monospace";
          "fontSize" = 20;
        };
      };

      # LLDB specific settings
      "lldb" = {
        "commandCompletions" = true;
        "evaluateForHovers" = true;
        "launch" = {
          "terminal" = "integrated";
        };
        "suppressMissingSourceFiles" = true;
      };
    };
  };
} 
