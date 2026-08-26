_: {
  # The OPERATOR's editor taste for any PROJECT home — cage or native alike.
  #
  # Separate from `devbox-cage` because taste follows the PERSON, not the placement: a project home is a
  # project home whether it is caged or native, and the first cut of this lived in the cage base only,
  # which silently gave native projects no theme at all.
  #
  # `mkDefault` throughout: a project may contest any of these and should win, because the project knows
  # what the repo is written in. What the project must NOT set is anything in here.
  flake.modules.homeManager.happygopher-vscode-taste =
    { lib, pkgs, ... }:
    {
      editors.vscode = {
        extensions = [ pkgs.vscode-extensions.dracula-theme.theme-dracula ];
        settings = {
          # The LABEL the extension registers, measured from its package.json `contributes.themes`:
          # "Dracula Theme" and "Dracula Theme Soft". There is no theme called "Dracula" — VS Code
          # silently falls back to its own default when `colorTheme` names one that does not exist,
          # which is why this read as "no theme applied" rather than as an error.
          "workbench.colorTheme" = lib.mkDefault "Dracula Theme";
          "editor.fontSize" = lib.mkDefault 20;
        };
      };
    };
}
