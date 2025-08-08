{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    # AI-Assisted Development Tools
    bmad-method # Universal AI Agent Framework
    markdown-tree-parser # Markdown document sharding tool
  ];
}
