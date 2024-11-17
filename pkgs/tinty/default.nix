{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "tinty";
  version = "0.23.0";

  src = fetchFromGitHub {
    owner = "tinted-theming";
    repo = "tinty";
    rev = "v${version}";
    sha256 = "sha256-5KrXvE+RLkypqKg01Os09XGxrqv0fCMkeSD//E5WrZc=";
  };

  cargoHash = "sha256-qTHlSP9WN39KgU7Q/4/iS1H2XOikXiCAiZ/NSAFS9mM=";

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
