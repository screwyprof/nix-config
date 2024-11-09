{ lib, ... }: {
  platforms = {
    isDarwin = builtins.currentSystem == "aarch64-darwin" || 
               builtins.currentSystem == "x86_64-darwin";
    isLinux = !platforms.isDarwin;
  };
} 