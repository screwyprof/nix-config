{ pkgs, ... }:

let
  python = pkgs.python312;
in
{
  home = {
    packages = with pkgs; [
      # Core Python
      python
      #poetry
      pipx

      # Development tools
      python.pkgs.pip
      python.pkgs.black
      #python.pkgs.ruff
      python.pkgs.pylint
      python.pkgs.pytest
      python.pkgs.pytest-cov
      python.pkgs.ipython

      # Common libraries
      python.pkgs.requests
      python.pkgs.pyyaml
    ];

    sessionVariables = {
      PYTHONPATH = "${python}/lib/python3.12/site-packages";
      PYTHONDONTWRITEBYTECODE = 1;
    };

    file.".config/pypoetry/config.toml".text = ''
      [virtualenvs]
      in-project = true
      create = true
      path = "{project-dir}/.venv"
    '';
  };
}
