{ config, pkgs, ... }: {
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    mutableExtensionsDir = false;

    profiles = {
      default = {
        enableExtensionUpdateCheck = false;
        enableUpdateCheck = false;

        # Nix vscode extensions
        extensions = with pkgs.vscode-extensions; [
          # Theme and UI
          dracula-theme.theme-dracula
          pkief.material-icon-theme
          pkief.material-product-icons

          # Language Support
          jnoortheen.nix-ide
          #golang.go
          #rust-lang.rust-analyzer
          # AI
          #anthropic.claude-code

          # c/c++
          #ms-vscode.cpptools-extension-pack
          #ms-vscode.cpptools
          #ms-vscode.cmake-tools

          # Development Tools
          #usernamehw.errorlens
          #fill-labs.dependi
          #eamodio.gitlens
          #ms-azuretools.vscode-docker
          tamasfe.even-better-toml
          formulahendry.auto-close-tag
          #ms-vscode.makefile-tools
          #ms-vscode.live-server
          #ryanluker.vscode-coverage-gutters

          # Testing and Debugging
          #vadimcn.vscode-lldb

          # Python Support
          #ms-python.python
          #ms-python.vscode-pylance

          # Remote Development
          #ms-vscode-remote.remote-ssh

          # Dev containers
          ms-vscode-remote.remote-containers
        ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          # Coverage Tools
          # {
          #   name = "vscode-coverage-gutters";
          #   publisher = "ryanluker";
          #   version = "2.12.0";
          #   sha256 = "sha256-Dkc/Wqc122fV1r6IUyHOtuRdpbWHL3elAhfxHcY6xtM";
          # }

          # Rust Tools
          # {
          #   name = "rust-test-lens";
          #   publisher = "hdevalke";
          #   version = "1.0.0";
          #   sha256 = "faSBpgFIyqA9F03ghizTyFaB+XOwA1pNrStQlLTV9Pk=";
          # }
          # {
          #   name = "rust-doc-viewer";
          #   publisher = "jscearcy";
          #   version = "4.2.0";
          #   sha256 = "x1pmrw8wYHWyNIJqVdoh+vasbHDG/A4m8vDZU0DnPzo=";
          # }
        ];

        userSettings = {
          # A temp hack to avoid errors for extensions which haven't migrated yet
          # https=//code.visualstudio.com/updates/v1_101#_web-environment-detection
          "extensions.supportNodeGlobalNavigator" = true;

          # Disable telemetry
          "telemetry.telemetryLevel" = "off";

          # Update settings
          "extensions.autoCheckUpdates" = false;
          "update.mode" = "none";

          # Disable AI slop
          # https://gist.github.com/rpavlik/95d6c40d8407805e2c20bdf6d9efa44e
          "accessibility.verboseChatProgressUpdates" = false;
          "accessibility.verbosity.inlineChat" = false;
          "accessibility.verbosity.panelChat" = false;
          "accessibility.verbosity.terminalChatOutput" = false;
          "chat.agent.codeBlockProgress" = false;
          "chat.agent.enabled" = false;
          "chat.agent.maxRequests" = 0;
          "chat.agent.thinking.generateTitles" = false;
          "chat.agent.thinking.terminalTools" = false;
          "chat.agentsControl.enabled" = false;
          "chat.agentSkillsLocations" = {
            ".agents/skills" = false;
            ".claude/skills" = false;
            ".github/skills" = false;
            "~/.agents/skills" = false;
            "~/.claude/skills" = false;
            "~/.copilot/skills" = false;
          };
          "chat.allowAnonymousAccess" = false;
          "chat.checkpoints.enabled" = false;
          "chat.commandCenter.enabled" = false;
          "chat.customAgentInSubagent.enabled" = false;
          "chat.detectParticipant.enabled" = false;
          "chat.disableAIFeatures" = true;
          "chat.editMode.hidden" = true;
          "chat.editRequests" = "none";
          "chat.extensionTools.enabled" = false;
          "chat.extensionUnification.enabled" = false;
          "chat.focusWindowOnConfirmation" = false;
          "chat.implicitContext.enabled" = {
            "panel" = "never";
          };
          "chat.implicitContext.suggestedContext" = false;
          "chat.includeApplyingInstructions" = false;
          "chat.instructionsFilesLocations" = {
            ".github/instructions" = false;
          };
          "chat.mcp.access" = "none";
          "chat.mcp.apps.enabled" = false;
          "chat.mcp.autostart" = "never";
          "chat.mcp.discovery.enabled" = {
            "claude-desktop" = false;
            "cursor-global" = false;
            "cursor-workspace" = false;
            "windsurf" = false;
          };
          "chat.mcp.gallery.enabled" = false;
          "chat.promptFiles" = false;
          "chat.promptFilesLocations" = {
            ".github/prompts" = false;
          };
          "chat.sendElementsToChat.attachCSS" = false;
          "chat.sendElementsToChat.attachImages" = false;
          "chat.sendElementsToChat.enabled" = false;
          "chat.setupFromDialog" = false;
          "chat.showAgentSessionsViewDescription" = false;
          "chat.tools.edits.autoApprove" = {
            "**/*" = false;
          };
          "chat.tools.terminal.autoApproveWorkspaceNpmScripts" = false;
          "chat.tools.terminal.enableAutoApprove" = false;
          "chat.tools.todos.showWidget" = false;
          "chat.unifiedAgentsBar.enabled" = false;
          "chat.useAgentSkills" = false;
          "chat.useAgentsMdFile" = false;
          "chat.useFileStorage" = false;
          "chat.viewSessions.enabled" = false;
          "dataWrangler.experiments.copilot.enabled" = false;
          "github.copilot.editor.enableAutoCompletions" = false;
          "github.copilot.editor.enableCodeActions" = false;
          "github.copilot.enable" = false;
          "github.copilot.nextEditSuggestions.enabled" = false;
          "github.copilot.renameSuggestions.triggerAutomatically" = false;
          "githubPullRequests.codingAgent.autoCommitAndPush" = false;
          "githubPullRequests.codingAgent.codeLens" = false;
          "githubPullRequests.codingAgent.enabled" = false;
          "githubPullRequests.codingAgent.uiIntegration" = false;
          "githubPullRequests.experimental.chat" = false;
          "gitlab.duoChat.enabled" = false;
          "inlineChat.holdToSpeech" = false;
          "inlineChat.lineNaturalLanguageHint" = false;
          "mcp" = {
            "inputs" = [ ];
            "servers" = { };
          };
          "notebook.experimental.generate" = false;
          "python.analysis.aiCodeActions" = {
            "convertFormatString" = false;
            "convertLambdaToNamedFunction" = false;
            "generateDocstring" = false;
            "generateSymbol" = false;
            "implementAbstractClasses" = false;
          };
          "python.experiments.enabled" = false;
          "redhat.telemetry.enabled" = false;
          "remote.SSH.experimental.chat" = false;
          "telemetry.feedback.enabled" = false;
          "terminal.integrated.initialHint" = false;
          "terminal.integrated.suggest.enabled" = false;
          "workbench.commandPalette.showAskInChat" = false;
          "workbench.editor.empty.hint" = "hidden";
          "workbench.settings.showAISearchToggle" = false;
          "workbench.secondarySideBar.defaultVisibility" = "hidden";

          # Update settings
          #"extensions.autoCheckUpdates" = false;
          #"update.mode" = "none";

          # Disable executing script on project startup
          "task.allowAutomaticTasks" = "off";

          # Remote settings
          #"remote.SSH.configFile" = "~/.ssh/config";

          "json.schemaDownload.enable" = false;
          "window.openFilesInNewWindow" = "on";
          "window.zoomLevel" = 1;

          # Terminal settings
          "terminal.integrated.fontFamily" = "'MesloLGMDZ Nerd Font'; 'JetBrainsMono NF'; 'FiraCode Nerd Font'; monospace";
          "terminal.integrated.fontSize" = 20;
          "terminal.integrated.defaultProfile.osx" = "zsh";
          "terminal.integrated.profiles.osx" = {
            "zsh" = {
              "path" = "${config.home.homeDirectory}/.nix-profile/bin/zsh";
            };
          };

          # # LLDB settings
          # "lldb.commandCompletions" = true;
          # "lldb.evaluateForHovers" = true;
          # "lldb.launch.terminal" = "integrated";
          # "lldb.suppressMissingSourceFiles" = true;

          # # Coverage Settings
          # "coverage-gutters.coverageFileNames" = [
          #   "target/coverage/lcov.info"
          # ];
          # "coverage-gutters.showGutterCoverage" = true;
          # "coverage-gutters.showLineCoverage" = true;
          # "coverage-gutters.showRulerCoverage" = true;
          # "coverage-gutters.highlightdark" = "rgba(64;128;64;0.4)";

          # # Go settings
          # "[go]" = {
          #   "editor.codeActionsOnSave" = {
          #     "source.organizeImports" = "explicit";
          #   };
          #   "editor.formatOnSave" = true;
          #   "editor.snippetSuggestions" = "none";
          # };
          # "go.lintTool" = "golangci-lint";
          # "go.testOnSave" = false;
          # "go.toolsManagement.autoUpdate" = false;
          # "go.useLanguageServer" = true;
          # "go.testFlags" = [ "-v" ];
          # "go.coverOnSave" = false;
          # "go.coverOnSingleTest" = true;
          # "go.coverOnSingleTestFile" = true;
          # "go.delveConfig" = {
          #   "debugAdapter" = "dlv-dap";
          #   "showGlobalVariables" = true;
          # };
          # "go.coverageDecorator" = {
          #   "type" = "highlight";
          #   "coveredHighlightColor" = "rgba(64;128;128;0.2)";
          #   "uncoveredHighlightColor" = "rgba(128;64;64;0.2)";
          #   "coveredBorderColor" = "rgba(64;128;128;0.4)";
          #   "uncoveredBorderColor" = "rgba(128;64;64;0.4)";
          # };

          # "[python]" = {
          #   "editor.codeActionsOnSave" = {
          #     "source.organizeImports" = "explicit";
          #   };
          #   "editor.defaultFormatter" = "ms-python.python";
          #   "editor.formatOnSave" = true;
          # };
          # "python.defaultInterpreterPath" = "${pkgs.python312}/bin/python3";

          # "[rust]" = {
          #   "editor.defaultFormatter" = "rust-lang.rust-analyzer";
          #   "editor.formatOnSave" = true;
          #   "editor.inlayHints.enabled" = "onUnlessPressed";
          # };

          # # Rust analyzer settings
          # "rust-analyzer.cargo.features" = "all";
          # "rust-analyzer.check.command" = "clippy";
          # "rust-analyzer.check.extraArgs" = [ ];
          # "rust-analyzer.completion.autoself.enable" = true;
          # "rust-analyzer.files.excludeDirs" = [
          #   "**/.git/**"
          #   "**/target/**"
          # ];
          # "rust-analyzer.hover.actions.enable" = true;
          # "rust-analyzer.inlayHints.parameterHints.enable" = true;
          # "rust-analyzer.inlayHints.renderColons" = true;
          # "rust-analyzer.inlayHints.typeHints.enable" = true;
          # "rust-analyzer.lens.enable" = true;
          # "rust-analyzer.lens.run.enable" = true;
          # "rust-analyzer.lens.implementations.enable" = true;
          # "rust-analyzer.lens.references.adt.enable" = true;
          # "rust-analyzer.lens.references.method.enable" = true;
          # "rust-analyzer.lens.references.trait.enable" = true;

          # Font settings
          "editor.fontFamily" = "'MesloLGMDZ Nerd Font'; 'JetBrainsMono NF'; 'FiraCode Nerd Font'; monospace";
          "editor.fontLigatures" = true;
          "editor.fontSize" = 20;
          "editor.lineHeight" = 30;
          "editor.inlayHints.enabled" = "onUnlessPressed";
          "editor.inlineSuggest.enabled" = true;
          "chat.editor.fontFamily" = "'MesloLGMDZ Nerd Font'; 'JetBrainsMono NF'; 'FiraCode Nerd Font'; monospace";
          "debug.console.fontFamily" = "'MesloLGMDZ Nerd Font';'JetBrainsMono NF'; 'FiraCode Nerd Font'; monospace";
          "debug.console.fontSize" = 20;

          # # File settings
          # "files.associations" = {
          #   "*.rs" = "rust";
          #   "*.go" = "go";
          # };

          # Theme and icon settings
          "material-icon-theme.activeIconPack" = "nest";
          "material-icon-theme.files.color" = "#42a5f5";
          "material-icon-theme.folders.color" = "#6bc1ff";
          "material-icon-theme.hidesExplorerArrows" = true;
          "workbench.iconTheme" = "material-icon-theme";
          "workbench.productIconTheme" = "material-product-icons";
          "workbench.colorTheme" = "Dracula Theme";
          "workbench.preferredDarkColorTheme" = "Dracula Theme";

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
    };
  };
}
