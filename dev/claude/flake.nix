{
  description = "Claude Code Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    claude-code.url = "github:sadjow/claude-code-nix";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { nixpkgs, claude-code, sops-nix, ... }: {
    devShells.aarch64-darwin.default =
      let
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfree = true;
        };

        version = "2025.8.4";

        mcp-sequential-thinking = pkgs.buildNpmPackage {
          pname = "mcp-servers-sequential-thinking";
          inherit version;

          src = pkgs.fetchFromGitHub {
            owner = "modelcontextprotocol";
            repo = "servers";
            rev = version;
            hash = "sha256-wD0OToLGy9Jyid4PaC8+dqAkIhDQY0c9CT7gcTLMz2Y=";
          };

          npmDepsHash = "sha256-qIsj4XCMqFxqsfjZzs/eDM57U+BI3yJ6h6sdMHXgLvU=";
          buildInputs = [ pkgs.nodejs ];

          installPhase = ''
            mkdir -p $out/bin
            cp -r src node_modules $out/
            cat > $out/bin/mcp-server-sequential-thinking << EOF
            #!${pkgs.nodejs}/bin/node
            require('$out/src/sequentialthinking/dist/index.js');
            EOF
            chmod +x $out/bin/mcp-server-sequential-thinking
          '';
        };

        mcp-config = pkgs.writeText "mcp.json" (builtins.toJSON {
          mcpServers = {
            "sequential-thinking" = {
              type = "stdio";
              command = "${mcp-sequential-thinking}/bin/mcp-server-sequential-thinking";
              args = [ ];
              env = { };
            };
          };
        });
      in

      pkgs.mkShell {
        buildInputs = with pkgs; [
          mcp-sequential-thinking
          # Documentation tools
          markdownlint-cli
          # Secrets management
          sops
          age
        ];

        shellHook = ''
          set -euo pipefail

          # 1) Ensure 'claude' is available
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
          if [ ! -f .mcp.json ]; then
            cp ${mcp-config} .mcp.json && echo "✓ .mcp.json created"
          else
            echo "⚠️ .mcp.json exists, skipping creation"
          fi

          # 5) Export CLAUDE_PROJECT_DIR for potential use
          export CLAUDE_PROJECT_DIR="$PROJECT_ROOT"

          # 5.1) Custom Claude API
          export ZHIPU_API_KEY="$(cat ~/.config/sops-nix/secrets/zhipu_api_key)"
          export ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic
          export ANTHROPIC_AUTH_TOKEN=$ZHIPU_API_KEY
          export ANTHROPIC_MODEL=glm-4.6
          export ANTHROPIC_DEFAULT_HAIKU_MODEL=glm-4.5-air
          export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
          
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
}
