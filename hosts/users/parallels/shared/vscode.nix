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

      # Theme settings
      "workbench.colorTheme" = "One Dark";
      "workbench.iconTheme" = "material-icon-theme";
      "workbench.colorCustomizations" = {
        "editorError.border" = "#fff0";
        "editorError.foreground" = "#fff0";
        "editorWarning.border" = "#fff0";
        "editorWarning.foreground" = "#fff0";
     };
      "editor.tokenColorCustomizations" = {
        "textMateRules" = [
          {
            "name" = "One Dark italic";
            "scope" = [
              "comment"
              "entity.other.attribute-name"
              "keyword"
              "markup.underline.link"
              "storage.modifier"
              "storage.type"
              "string.url"
              "variable.language.super"
              "variable.language.this"
            ];
            "settings" = {
              "fontStyle" = "italic";
            };
          }
          {
            "name" = "One Dark italic reset";
            "scope" = [
              "keyword.operator"
              "keyword.other.type"
              "storage.modifier.import"
              "storage.modifier.package"
              "storage.type.built-in"
              "storage.type.function.arrow"
              "storage.type.generic"
              "storage.type.java"
              "storage.type.primitive"
            ];
            "settings" = {
              "fontStyle" = "";
            };
          }
        ];
      };
    };
  };
} 
