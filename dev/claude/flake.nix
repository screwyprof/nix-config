{
  description = "Nix project development tools";

  # Optional: Use flake-utils to support multiple systems with less boilerplate
  # inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    claude-code.url = "github:sadjow/claude-code-nix";
  };

  outputs = { nixpkgs, claude-code, ... }: {
    devShells.aarch64-darwin.default =
      let
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfree = true;
        };

        mcp-sequential-thinking = pkgs.buildNpmPackage {
          pname = "mcp-servers-sequential-thinking";
          version = "master";

          src = pkgs.fetchFromGitHub {
            owner = "modelcontextprotocol";
            repo = "servers";
            rev = "master";
            hash = "sha256-DzyxjbE6famKru3a3GIFDoP8WWqGL+oUlitJP8Zqt/M=";
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
        buildInputs = [ mcp-sequential-thinking ];

        shellHook = ''
          set -euo pipefail

          # 1) Ensure 'claude' is available
          if ! command -v claude >/dev/null 2>&1; then
            echo "❌ Error: 'claude' binary not found in PATH. Please install Claude Code before proceeding."
            return 1
          fi

          # 2) Project root & stable hash
          PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
          PROJECT_HASH=$(printf '%s\n' "$PROJECT_ROOT" | shasum -a 256 | cut -c1-8)

          # 3) Isolated state dir via XDG
          if [ -n "$XDG_STATE_HOME" ]; then
            STATE_BASE="$XDG_STATE_HOME"
          else
            STATE_BASE="$HOME/.local/state"
          fi

          export CLAUDE_CONFIG_DIR="$STATE_BASE/claude/$PROJECT_HASH"
          export CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR=true
          mkdir -p "$CLAUDE_CONFIG_DIR"

          # 4) Ensure .mcp.json is present; warn if it already exists
          if [ ! -f .mcp.json ]; then
            cp ${mcp-config} .mcp.json && echo "✓ .mcp.json created"
          else
            echo "⚠️ .mcp.json exists, skipping creation"
          fi

          # 5) Suggest init if needed
          if [ ! -d .claude ]; then
            echo "💡 No .claude directory found. You can initialize project settings by running 'claude /init'."
          fi

          # 6) Summary message
          cat <<-EOF

          🔧 Claude Code dev shell ready

            • CLAUDE_CONFIG_DIR: $CLAUDE_CONFIG_DIR
            • Project .claude/ (settings) → repo
            • Runtime state → $STATE_BASE/claude/$PROJECT_HASH

          Available commands:
            • claude           Start Claude Code (isolated state)
            • claude mcp list  List configured MCP servers

          EOF
        '';
      };
  };
}
