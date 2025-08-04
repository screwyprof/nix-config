{ lib
, buildNpmPackage
, fetchFromGitHub
, nodejs_20
, makeWrapper
}:

buildNpmPackage rec {
  pname = "bmad-method";
  version = "4.34.0";

  src = fetchFromGitHub {
    owner = "bmadcode";
    repo = "BMAD-METHOD";
    rev = "v${version}";
    hash = "sha256-O5pdS2g8u35jc2Kl5H+/A3rvsH6a4yniq89BWjPTfhQ=";
  };

  npmDepsHash = "sha256-ocel1BUai6DJI4c05B4N0WUrhwTxUk1PLSIsVDeE/3c=";

  # The package requires Node.js v20+
  nodejs = nodejs_20;

  nativeBuildInputs = [ makeWrapper ];

  # The main package handles everything through bmad-npx-wrapper.js
  # We just need to ensure it can find all resources
  postInstall = ''
    # The installed package structure needs adjustment for Nix
    # The wrapper expects to find the installer in tools/installer relative to itself
    
    # Create a proper wrapper that ensures the package can find its resources
    wrapProgram $out/bin/bmad-method \
      --set BMAD_SOURCE_ROOT "$out/lib/node_modules/bmad-method" \
      --prefix PATH : ${lib.makeBinPath [ nodejs_20 ]}
    
    # Also wrap the alternate name
    if [ -f "$out/bin/bmad" ]; then
      wrapProgram $out/bin/bmad \
        --set BMAD_SOURCE_ROOT "$out/lib/node_modules/bmad-method" \
        --prefix PATH : ${lib.makeBinPath [ nodejs_20 ]}
    fi
    
    # Create convenience wrappers
    makeWrapper $out/bin/bmad-method $out/bin/bmad-install \
      --add-flags "install"
    
    makeWrapper $out/bin/bmad-method $out/bin/bmad-flatten \
      --add-flags "flatten"
    
    makeWrapper $out/bin/bmad-method $out/bin/bmad-build \
      --add-flags "build"
  '';

  meta = with lib; {
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
}
