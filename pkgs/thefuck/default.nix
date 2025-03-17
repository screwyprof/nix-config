{ lib, stdenv, fetchFromGitHub, python3, libffi }:

let
  python = python3.override {
    packageOverrides = _: super: {
      # Ensure psutil has the necessary dependencies
      psutil = super.psutil.overridePythonAttrs (old: {
        buildInputs = (old.buildInputs or [ ]) ++ [ libffi ];
      });
    };
  };
in
python.pkgs.buildPythonApplication rec {
  pname = "thefuck";
  version = "3.32";

  src = fetchFromGitHub {
    owner = "nvbn";
    repo = "thefuck";
    rev = version;
    sha256 = "sha256-bRCy95owBJaxoyCNQF6gEENoxCkmorhyKzZgU1dQN6I=";
  };

  propagatedBuildInputs = with python.pkgs; [
    colorama
    decorator
    psutil
    pyte
    six
  ];

  checkInputs = with python.pkgs; [
    pytest
    pytest-mock
  ];

  doCheck = false;

  meta = with lib; {
    homepage = "https://github.com/nvbn/thefuck";
    description = "Magnificent app which corrects your previous console command";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
