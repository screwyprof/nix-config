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

  useFetchCargoVendor = true;
  cargoHash = "sha256-Wa5mKigUzSvZkUa+/XzZD3qO3gothD/Ams7ceoRT7Yg=";

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [ libiconv ];

  postInstall = ''
    wrapProgram $out/bin/navi \
      --prefix PATH : "$out/bin " \
      --prefix PATH : ${lib.makeBinPath([ wget ] ++ lib.optionals withFzf [ fzf ])}
  '';

  # Disable tests completely to avoid permission issues
  doCheck = false;

  meta = with lib; {
    description = "Interactive cheatsheet tool for the command-line and application launchers";
    homepage = "https://github.com/denisidoro/navi";
    license = licenses.asl20;
    platforms = platforms.unix;
    mainProgram = "navi";
    maintainers = with maintainers; [ cust0dian ];
  };
}

