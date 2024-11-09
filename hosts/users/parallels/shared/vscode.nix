{ config, pkgs, lib, ... }: {
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    mutableExtensionsDir = false;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
    
    extensions = with pkgs.vscode-extensions; [
      # Core extensions available in nixpkgs
      bbenoist.nix
      eamodio.gitlens
      #github.copilot
      golang.go
      rust-lang.rust-analyzer
      ms-azuretools.vscode-docker
      vadimcn.vscode-lldb
      tamasfe.even-better-toml

      pkgs.vscode-extensions.mskelton.one-dark-theme
      pkgs.vscode-extensions.pkief.material-icon-theme

      #pkgs.vscode-extensions.equinusocio.vsc-material-theme
      #pkgs.vscode-extensions.equinusocio.vsc-material-theme-icons

      #pkgs.vscode-extensions.ms-vscode-remote.remote-containers
      #pkgs.vscode-extensions.github.vscode-github-actions
      #pkgs.vscode-extensions.ritwickdey.liveserver
      pkgs.vscode-extensions.usernamehw.errorlens
      pkgs.vscode-extensions.formulahendry.auto-close-tag
      pkgs.vscode-extensions.ms-vscode.makefile-tools

      pkgs.vscode-extensions.ms-vscode.test-adapter-converter
      pkgs.vscode-extensions.hbenl.vscode-test-explorer
      
    ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
    #   {
    #     name = "vsc-material-theme";
    #     publisher = "equinusocio";
    #     version = "34.7.5";
    #     sha256 = "6YMr64MTtJrmMMMPW/s6hMh/IilDqLMrspKRPT4uSpM=";
    #   }
    #   {
    #     name = "vsc-material-theme-icons";
    #     publisher = "equinusocio";
    #     version = "3.8.8";
    #     sha256 = "el2hQaq1gZBn2PZ+f+S1fHM/g3V0sX7Chyre04sds8k=";
    #   }
    #  {
    #     name = "material-icon-theme";
    #     publisher = "pkief";
    #     version = "5.12.0";
    #     sha256 = "FLHEaWFZ9JAy8S1il10D/2qQG7aNH8n6iA+kFhUTZVs=";
    #   }
      {
        name = "dependi";
        publisher = "fill-labs";
        version = "0.7.10";
        sha256 = "m8W21ztTmEOjDI1KCymeBgQzg9jdgKG9dCFp+U1D818=";
      }
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
      # Update settings
      "update.mode" = "none";
      "extensions.autoUpdate" = false;
      "extensions.autoCheckUpdates" = false;

      # Editor settings
      "editor.fontFamily" = "'JetBrainsMono', 'FiraCode Nerd Font', monospace";
      "editor.fontLigatures" = true;
      "editor.fontSize" = 20;
      "editor.lineHeight" = 30;

      # Terminal settings
      "terminal.integrated.fontSize" = 18;
      "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font'";

      # Go specific settings
      "[go]" = {
        "editor.formatOnSave" = true;
        "editor.codeActionsOnSave" = {
          "source.organizeImports" = "explicit";
        };
        "editor.snippetSuggestions" = "none";
      };

      "go.useLanguageServer" = true;
      "go.toolsManagement.autoUpdate" = false;
      "go.lintTool" = "golangci-lint";
      "go.testOnSave" = false;
      "go.coverOnSave" = false;
      "go.coverOnSingleTest" = true;

      # Debugging settings for Go
      "go.delveConfig" = {
        "debugAdapter" = "dlv-dap";  # Use the DAP protocol
        "showGlobalVariables" = true;
      };

      # Material Theme settings
      #"materialTheme.accent" = "Purple";
      #"materialTheme.accent" = "Teal";
      #"materialTheme.autoApplyIcons" = true;
      #"materialTheme.fixIconsRunning" = false;
      #"materialTheme.themeVariant" = "Darker";
      #"workbench.colorTheme" = "Material Theme";
      #"workbench.iconTheme" = "material-icon-theme";
      "workbench.colorTheme" = "One Dark";
      "workbench.iconTheme" = "material-icon-theme";
      "workbench.colorCustomizations" = {
        "editorError.border" = "#fff0";
        "editorError.foreground" = "#fff0";
        "editorWarning.border" = "#fff0";
        "editorWarning.foreground" = "#fff0";
     };
    };
  };
} 
