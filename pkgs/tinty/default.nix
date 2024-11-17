{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "tinty";
  version = "0.22.0";

  src = fetchFromGitHub {
    owner = "tinted-theming";
    repo = "tinty";
    rev = "v${version}";
    sha256 = "sha256-CZ++Njxt19pB2om2tvOYnprvCR1p7Xc1ZFR/LfI2064=";
  };

  cargoHash = "sha256-8d7OkxNfCDreS2D1w8b5CUrEs0PgGORzJsYBUPZ6J0M=";

  # TODO(fix testsDisable tests for now as they require specific CI setup
  doCheck = false;

  # If we want to enable tests later, we'll need to:
  # 1. Set up proper environment variables
  # 2. Create test fixtures
  # 3. Run tests in single thread mode
  # As shown in .github/workflows/test.yml

  # Configure tests to run one at a time and with proper setup
  #   checkPhase = ''
  #     # Create test fixtures
  #     ./scripts/create_fixtures

  #     # Run tests with single thread
  #     cargo test --release --all-targets --all-features -- --test-threads=1
  #   '';

  meta = with lib; {
    description = "A theme manager for tinted-theming";
    homepage = "https://github.com/tinted-theming/tinty";
    license = licenses.mit;
    maintainers = [ ];
  };
}
