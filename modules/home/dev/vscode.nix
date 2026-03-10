{
  flake.modules.homeManager.dev-vscode =
    { config, pkgs, ... }:
    {
      programs.vscode = {
        enable = true;
        package = pkgs.vscode;
        mutableExtensionsDir = false;

        profiles = {
          default = {
            enableExtensionUpdateCheck = false;
            enableUpdateCheck = false;

            extensions = with pkgs.vscode-extensions; [
              # Theme and UI
              dracula-theme.theme-dracula
              pkief.material-icon-theme
              pkief.material-product-icons

              # Language Support
              jnoortheen.nix-ide

              # Development Tools
              tamasfe.even-better-toml
              formulahendry.auto-close-tag

              # Dev containers
              ms-vscode-remote.remote-containers
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

              # Don't recomend to install extensions.
              "extensions.ignoreRecommendations" = true;

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

              # Disable executing script on project startup
              "task.allowAutomaticTasks" = "off";

              "json.schemaDownload.enable" = false;
              "window.openFilesInNewWindow" = "on";
              "window.zoomLevel" = 1;

              # Terminal settings
              "terminal.integrated.shellIntegration.enabled" = false;
              "terminal.integrated.fontFamily" =
                "'MesloLGMDZ Nerd Font Mono', 'JetBrainsMono NF', 'FiraCode Nerd Font Mono', monospace";
              "terminal.integrated.fontSize" = 20;
              "terminal.integrated.fontLigatures.enabled" = true;
              "terminal.integrated.defaultProfile.osx" = "zsh";
              "terminal.integrated.profiles.osx" = {
                "zsh" = {
                  "path" = "${config.home.homeDirectory}/.nix-profile/bin/zsh";
                };
              };
              "terminal.integrated.autoReplies" = {
                "Done. Press any key to close the terminal." = "\r";
              };

              # Font settings
              "editor.fontFamily" =
                "'MesloLGMDZ Nerd Font Mono', 'JetBrainsMono NF', 'FiraCode Nerd Font Mono', monospace";
              "editor.fontLigatures" = true;
              "editor.fontSize" = 20;
              "editor.lineHeight" = 30;
              "editor.inlayHints.enabled" = "onUnlessPressed";
              "editor.inlineSuggest.enabled" = true;
              "chat.editor.fontFamily" =
                "'MesloLGMDZ Nerd Font Mono', 'JetBrainsMono NF', 'FiraCode Nerd Font Mono', monospace";
              "debug.console.fontFamily" =
                "'MesloLGMDZ Nerd Font Mono', 'JetBrainsMono NF', 'FiraCode Nerd Font Mono', monospace";
              "debug.console.fontSize" = 20;

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
    };
}
