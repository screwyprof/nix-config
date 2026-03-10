{
  flake.modules.homeManager.dev-python =
    { pkgs, ... }:
    let
      python = pkgs.python312;
    in
    {
      home = {
        packages = with pkgs; [
          python
          pipx
          python.pkgs.pip
          python.pkgs.black
          python.pkgs.pylint
          python.pkgs.pytest
          python.pkgs.pytest-cov
          python.pkgs.ipython
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
    };
}
