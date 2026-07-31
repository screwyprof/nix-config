{
  flake.modules.homeManager.dev-vscode =
    { pkgs, ... }:
    let
      fontFamily = "'MesloLGMDZ Nerd Font Mono', 'JetBrainsMono NF', 'FiraCode Nerd Font Mono', monospace";

      disableAI = {
        "accessibility.verboseChatProgressUpdates" = false;
        "accessibility.verbosity.inlineChat" = false;
        "accessibility.verbosity.panelChat" = false;
        "accessibility.verbosity.terminalChatOutput" = false;
        "chat.agent.codeBlockProgress" = false;
        "chat.agent.enabled" = false;
        "chat.agentHost.enabled" = false;
        "chat.agent.maxRequests" = 0;
        "chat.agent.thinking.generateTitles" = false;
        "chat.agent.thinking.terminalTools" = false;
        "chat.agentsControl.enabled" = "hidden";
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
        # Correct ids for the remote agent host. This block previously carried
        # `chat.remoteAgentHosts.enabled`, which is the LOCALIZATION key, not a setting — VS Code drops
        # unknown ids without warning, so it sat here doing nothing. The real id has NO DOT before
        # `Enabled`. Confirmed against microsoft/vscode at tags 1.129.1 and 1.131.0
        # (`RemoteAgentHostsEnabledSettingId`, `default: true`, scope APPLICATION — so USER settings only,
        # workspace will not take). `chat.agentHost.enabled` above is a different, LOCAL-only gate.
        #
        # THESE DO NOT STOP THE REMOTE AGENT-HOST DOWNLOAD. Tested 2026-07-31 with both set false and
        # verified present in settings.json, VS Code fully quit, remote ~/.vscode-server wiped: the ~635MB
        # agent-host server was fetched anyway. The client log shows why — it is fetched by the CLI
        # bootstrap ~4s BEFORE the workbench process exists, and `ensure_supervisor_running` is called
        # unconditionally from `cli/src/commands/tunnels.rs:165`. vscode PR #316701 gates the CONNECT paths
        # behind the setting, not the INSTALL. Filed upstream as microsoft/vscode#328397.
        #
        # Kept because they are the correct ids and AutoConnect does stop unprompted outbound connections to
        # configured remote agent hosts. The download is handled elsewhere, not by configuration.
        # Undocumented and tagged experimental upstream — re-check after a VS Code update.
        "chat.remoteAgentHostsAutoConnect" = false;
        "chat.remoteAgentHostsEnabled" = false;
        "chat.sendElementsToChat.attachCSS" = false;
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
      };
    in
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

              # Remote-SSH (devbox VM)
              ms-vscode-remote.remote-ssh

              # direnv bridge: extensions see the project devshell PATH (local opens)
              mkhl.direnv
            ];

            userSettings = disableAI // {
              # A temp hack to avoid errors for extensions which haven't migrated yet
              # https=//code.visualstudio.com/updates/v1_101#_web-environment-detection
              "extensions.supportNodeGlobalNavigator" = true;

              # Disable telemetry
              "telemetry.telemetryLevel" = "off";

              # Update settings
              "extensions.autoUpdate" = "off";
              "extensions.autoCheckUpdates" = false;
              "update.mode" = "none";

              # Don't recomend to install extensions.
              "extensions.ignoreRecommendations" = true;

              # Remote substrate only (peer of direnv-in-VM): everything else is
              # declared per-project in .vscode/extensions.json
              #"remote.SSH.defaultExtensions" = [ "mkhl.direnv" ];

              # Install remote extensions directly from marketplace instead of copying from localhost
              "remote.SSH.localServerDownload" = "off";

              # vscode tries to shove up copilot up your throat by defaul to remote causing cryptic EntryWriteLocked.
              "remote.defaultExtensionsIfInstalledLocally" = [ ];

              # Let Ctrl+B reach the terminal (tmux prefix) instead of toggling the sidebar
              "terminal.integrated.commandsToSkipShell" = [ "-workbench.action.toggleSidebarVisibility" ];

              # Disable executing script on project startup
              "task.allowAutomaticTasks" = "off";

              "json.schemaDownload.enable" = false;
              "window.openFilesInNewWindow" = "on";
              "window.zoomLevel" = 1;

              # Terminal settings
              "terminal.integrated.shellIntegration.enabled" = false;
              "terminal.integrated.fontFamily" = fontFamily;
              "terminal.integrated.fontSize" = 20;
              "terminal.integrated.fontLigatures.enabled" = true;
              "terminal.integrated.autoReplies" = {
                "Done. Press any key to close the terminal." = "\r";
              };

              # Font settings
              "editor.fontFamily" = fontFamily;
              "editor.fontLigatures" = true;
              "editor.fontSize" = 20;
              "editor.lineHeight" = 30;
              "editor.inlayHints.enabled" = "onUnlessPressed";
              "editor.inlineSuggest.enabled" = true;
              "chat.editor.fontFamily" = fontFamily;
              "debug.console.fontFamily" = fontFamily;
              "debug.console.fontSize" = 20;

              # Go
              "[go]" = {
                "editor.codeActionsOnSave" = {
                  "source.organizeImports" = "explicit";
                };
                "editor.formatOnSave" = true;
                "editor.snippetSuggestions" = "none";
              };
              "go.diagnostic.vulncheck" = "Off";
              "go.coverOnSave" = true;
              "go.coverOnSingleTest" = true;
              "go.coverOnSingleTestFile" = true;
              "go.coverageDecorator" = {
                "coveredBorderColor" = "rgba(64,128,128,0.4)";
                "coveredHighlightColor" = "rgba(64,128,128,0.2)";
                "type" = "highlight";
                "uncoveredBorderColor" = "rgba(128,64,64,0.4)";
                "uncoveredHighlightColor" = "rgba(128,64,64,0.2)";
              };
              "go.delveConfig" = {
                "debugAdapter" = "dlv-dap";
                "showGlobalVariables" = true;
              };
              "go.lintTool" = "golangci-lint";
              "go.testFlags" = [ "-v" ];
              "go.testOnSave" = false;
              "go.toolsManagement.autoUpdate" = false;
              "go.useLanguageServer" = true;

              # Rust
              "[rust]" = {
                "editor.defaultFormatter" = "rust-lang.rust-analyzer";
                "editor.formatOnSave" = true;
                "editor.inlayHints.enabled" = "onUnlessPressed";
              };
              "rust-analyzer.cargo.features" = "all";
              "rust-analyzer.check.command" = "clippy";
              "rust-analyzer.check.extraArgs" = [ ];
              "rust-analyzer.completion.autoself.enable" = true;
              "rust-analyzer.hover.actions.enable" = true;
              "rust-analyzer.hover.documentation.enable" = true;
              "rust-analyzer.hover.documentation.keywords.enable" = true;
              "rust-analyzer.hover.actions.implementations.enable" = true;
              "rust-analyzer.hover.actions.references.enable" = true;
              "rust-analyzer.hover.actions.run.enable" = true;
              "rust-analyzer.hover.actions.debug.enable" = true;
              "rust-analyzer.inlayHints.parameterHints.enable" = true;
              "rust-analyzer.inlayHints.renderColons" = true;
              "rust-analyzer.inlayHints.typeHints.enable" = true;
              "rust-analyzer.lens.enable" = true;
              "rust-analyzer.lens.run.enable" = true;
              "rust-analyzer.lens.implementations.enable" = true;
              "rust-analyzer.lens.references.adt.enable" = true;
              "rust-analyzer.lens.references.method.enable" = true;
              "rust-analyzer.lens.references.trait.enable" = true;

              # LLDB
              "lldb.commandCompletions" = true;
              "lldb.evaluateForHovers" = true;
              "lldb.launch.terminal" = "integrated";
              "lldb.suppressMissingSourceFiles" = true;

              # Testing
              "testing.coverageToolbarEnabled" = true;
              "testing.showCoverageInExplorer" = true;
              "coverage-gutters.coverageFileNames" = [
                "coverage.out"
                "coverage.html"
                "lcov.info"
              ];
              "coverage-gutters.showGutterCoverage" = true;
              "coverage-gutters.showLineCoverage" = true;
              "coverage-gutters.showRulerCoverage" = true;
              "coverage-gutters.highlightdark" = "rgba(64,128,64,0.4)";

              # File associations
              "files.associations" = {
                "*.go" = "go";
                "*.rs" = "rust";
                "*.toml" = "toml";
              };
              "makefile.configureOnOpen" = false;

              # Theme and icon settings
              "material-icon-theme.activeIconPack" = "nest";
              "material-icon-theme.files.color" = "#42a5f5";
              "material-icon-theme.folders.color" = "#6bc1ff";
              "material-icon-theme.hidesExplorerArrows" = true;
              "workbench.iconTheme" = "material-icon-theme";
              "workbench.productIconTheme" = "material-product-icons";
              "workbench.colorTheme" = "Dracula Theme";
              "workbench.preferredDarkColorTheme" = "Dracula Theme";
            };
          };
        };
      };
    };
}
