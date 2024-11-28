{ stdenv, fetchFromGitHub, lib, makeWrapper, rustPlatform, wget, libiconv, withFzf ? true, fzf }:

rustPlatform.buildRustPackage rec {
  pname = "navi";
  version = "089be801b229e27dca7ea9d547726fe0f9a90e96";

  src = fetchFromGitHub {
    owner = "denisidoro";
    repo = "navi";
    rev = "${version}";
    sha256 = "sha256-8et38qn2ywKfaSxHSgAuMqcV+48nogfbMQgCzSB1bIg=";
  };

  cargoHash = "sha256-WYGLntosH4U36xbVQYOtgnx9uBqKrH7gTfqB/oJ1yNM=";

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [ libiconv ];

  postInstall = ''
    wrapProgram $out/bin/navi \
      --prefix PATH : "$out/bin " \
      --prefix PATH : ${lib.makeBinPath([ wget ] ++ lib.optionals withFzf [ fzf ])}
  '';

  preCheck = ''
    # Setup environment variables as in CI
    mkdir -p /tmp/cheats-dir
    touch /tmp/config-file
    export NAVI_PATH=/tmp/cheats-dir
    export NAVI_CONFIG=/tmp/config-file
  '';

  checkFlags = [
    # error: Found argument '--test-threads' which wasn't expected, or isn't valid in this context
    "--skip=test_parse_variable_line"
  ];

  meta = with lib; {
    description = "Interactive cheatsheet tool for the command-line and application launchers";
    homepage = "https://github.com/denisidoro/navi";
    license = licenses.asl20;
    platforms = platforms.unix;
    mainProgram = "navi";
    maintainers = with maintainers; [ cust0dian ];
  };
}

