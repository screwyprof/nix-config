{
  description = "Claude Code Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        devShells.default = pkgs.mkShellNoCC {
          packages = with pkgs; [
            # Documentation tools
            # markdownlint-cli
            claude-code
            nodejs # claude's vscode extension for some reason need it
          ];

          shellHook =
            let
              mcp-config = inputs.mcp-servers-nix.lib.mkConfig pkgs {
                programs = {
                  sequential-thinking.enable = true;
                  # ... other MCP configs
                };
              };

            in
            ''
              set -euo pipefail

              # 1) Ensure 'claude' is available in system
              if ! command -v claude >/dev/null 2>&1; then
                echo "❌ Error: 'claude' binary not found in PATH. Please install Claude Code before proceeding."
                return 1
              fi

              # 2) Project root & stable hash (only set if not already defined for shell stacking)
              PROJECT_ROOT="''${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
              PROJECT_HASH="''${PROJECT_HASH:-$(printf '%s\n' "$PROJECT_ROOT" | shasum -a 256 | cut -c1-8)}"

              # 3) Isolated state dir via XDG
              export CLAUDE_CONFIG_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/claude/$PROJECT_HASH"
              export CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR=true
              mkdir -p "$CLAUDE_CONFIG_DIR"

              # 4) Ensure .mcp.json is present; warn if it already exists
              if [ -L ".mcp.json" ]; then
                echo "⚠️ .mcp.json exists, unlinking"
                unlink .mcp.json
              fi
              ln -s ${mcp-config} .mcp.json

              # 5) Export CLAUDE_PROJECT_DIR for potential use
              export CLAUDE_PROJECT_DIR="$PROJECT_ROOT"

              # 5.1) Custom Claude API
              export ZHIPU_API_KEY="$(cat ~/.config/sops-nix/secrets/zhipu_api_key)"
              export ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic
              export ANTHROPIC_AUTH_TOKEN=$ZHIPU_API_KEY
              export ANTHROPIC_MODEL=glm-4.6
              export ANTHROPIC_DEFAULT_HAIKU_MODEL=glm-4.5-air
              export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
              export CLAUDE_CODE_SKIP_AUTH_LOGIN=1

              # 6) Suggest init if needed
              if [ ! -d .claude ]; then
                echo "💡 No .claude directory found. You can initialize project settings by running 'claude /init'."
              fi

              # 7) Summary message
              cat <<-EOF

              🔧 Claude Dev Shell Ready

                • CLAUDE_PROJECT_DIR: $CLAUDE_PROJECT_DIR
                • CLAUDE_CONFIG_DIR: $CLAUDE_CONFIG_DIR

              Available commands:
                • claude           Start Claude Code (isolated state)
                • claude mcp list  List configured MCP servers
                • markdownlint     Lint markdown files

              EOF
            '';
        };
      };
    };
}
