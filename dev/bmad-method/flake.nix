{
  description = "Universal AI Agent Framework for AI-assisted development";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        packages.bmad-method = pkgs.buildNpmPackage rec {
          pname = "bmad-method";
          version = "6.0.0-alpha.12";

          src = pkgs.fetchFromGitHub {
            owner = "bmad-code-org";
            repo = "BMAD-METHOD";
            rev = "9d510fc0751889a521f50fc3575393b09bd90e9b";
            hash = "sha256-QYH6M7qz++CuXYBeh4LWSlB1JByuinhuG3PwwAkt6Zs=";
          };

          npmDepsHash = "sha256-AJaVkMAkNmfGFqOoBjXbWLMJc14KjdWhIsB1RFYKQug=";

          # The package requires Node.js v20+
          nodejs = pkgs.nodejs_20;

          # This package doesn't have a build script - it's a CLI-only package
          dontNpmBuild = true;

          # Make sure we don't run npm prune which might remove needed dependencies
          npmPrune = false;


          nativeBuildInputs = [ pkgs.makeWrapper ];

          # Ensure the CLI can find the node_modules when installed via Nix
          postInstall = ''
            # The bmad-npx-wrapper.js handles execution properly
            # We need to set NODE_PATH to the directory containing the package
            wrapProgram $out/bin/bmad-method \
              --set NODE_PATH "$out/lib/node_modules/bmad-method" \
              --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.nodejs_20 ]}

            # Also wrap the alternate name
            if [ -f "$out/bin/bmad" ]; then
              wrapProgram $out/bin/bmad \
                --set NODE_PATH "$out/lib/node_modules/bmad-method" \
                --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.nodejs_20 ]}
            fi
          '';

          meta = with pkgs.lib; {
            description = "Universal AI Agent Framework for AI-assisted development";
            longDescription = ''
              BMad Method (Breakthrough Method of Agile AI-Driven Development) is a
              framework that transforms any domain with specialized AI expertise:
              software development, entertainment, creative writing, business strategy,
              and personal wellness. It provides AI agents that collaborate through
              detailed planning and context-engineered development workflows.

              Key features:
              - AI agents for different roles (PM, Architect, Dev, QA, etc.)
              - Support for multiple AI-powered IDEs (Cursor, Claude Code, etc.)
              - Document sharding for better context management
              - Codebase flattener for AI analysis
              - Web bundles for use with ChatGPT, Claude, and Gemini

              This package provides the complete BMad Method toolkit:
              - bmad-method / bmad: Main CLI tool
              - bmad-install: Quick installer for new projects
              - bmad-flatten: Codebase flattener for AI analysis
              - bmad-build: Build web bundles for AI platforms
            '';
            homepage = "https://github.com/bmadcode/BMAD-METHOD";
            license = licenses.mit;
            maintainers = with maintainers; [ ];
            mainProgram = "bmad-method";
            platforms = platforms.all;
          };
        };

        # Make bmad-method the default package
        packages.default = config.packages.bmad-method;

        # Development shell with bmad-method available
        devShells.default = pkgs.mkShell {
          buildInputs = [
            config.packages.bmad-method
            pkgs.nodejs_20
          ];

          shellHook = ''
            echo "🤖 BMad Method Development Environment"
            echo "======================================"
            bmad-method --version || echo "BMad Method not yet available"
            node --version
            echo ""
            echo "Usage:"
            echo "  bmad-method install     # Install BMad in current project directory"
            echo "  (After install, you get access to agents and workflows)"
            echo ""
            echo "Note: BMad Method is an installer that sets up AI agents in your project"
            echo ""
          '';
        };
      };
    };
}
