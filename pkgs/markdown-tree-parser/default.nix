{ lib
, buildNpmPackage
, fetchFromGitHub
, nodejs_20
}:

buildNpmPackage rec {
  pname = "markdown-tree-parser";
  version = "1.6.0";

  src = fetchFromGitHub {
    owner = "ksylvan";
    repo = "markdown-tree-parser";
    rev = "v${version}";
    hash = "sha256-FEFbF2ioVCgnkD+4GAjtMpKlSeRMDyTOAStpSJli5Xc=";
  };

  npmDepsHash = "sha256-ZqPr4bhTRYXMewYrpNAB6c3iqHJlYXiCp5LjLrOk9oQ=";

  nodejs = nodejs_20;

  # This package doesn't have a build script
  dontNpmBuild = true;

  meta = with lib; {
    description = "Parse and split large markdown documents efficiently";
    homepage = "https://github.com/ksylvan/markdown-tree-parser";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
    mainProgram = "md-tree";
  };
}
