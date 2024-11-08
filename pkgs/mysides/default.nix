{ lib
, stdenv
, fetchFromGitHub
, darwin
}:

stdenv.mkDerivation rec {
  pname = "mysides";
  version = "1.0.1";

  src = fetchFromGitHub {
    owner = "mosen";
    repo = "mysides";
    rev = "master";
    sha256 = "sha256-aAZOGeU8lvMPxBIHKbNNe5WVHvSfRpjgnqJ6qV4Jw00=";
  };

  buildInputs = [
    darwin.apple_sdk.frameworks.CoreServices
    darwin.apple_sdk.frameworks.Foundation
  ];

  # Set deployment target
  MACOSX_DEPLOYMENT_TARGET = "11.0";

  buildPhase = ''
    echo "Building mysides..."
    
    # Compile directly
    clang -arch arm64 \
          -framework CoreServices \
          -framework Foundation \
          -fobjc-arc \
          src/main.m \
          -o mysides
    
    echo "Build complete. Checking binary:"
    file mysides
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp mysides $out/bin/
    chmod +x $out/bin/mysides
    
    echo "Installed binary information:"
    file $out/bin/mysides
    otool -L $out/bin/mysides || true
  '';

  meta = with lib; {
    description = "macOS Finder sidebar management tool";
    homepage = "https://github.com/mosen/mysides";
    license = licenses.mit;
    platforms = [ "aarch64-darwin" ];
    maintainers = [];
  };
} 