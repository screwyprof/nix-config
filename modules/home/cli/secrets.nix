{
  flake.modules.homeManager.cli-secrets =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      home.packages = with pkgs; [
        age
        sops
      ];

      sops = {
        age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
        defaultSopsFile = ../../../secrets/secrets.yaml;
        environment.PATH = lib.mkForce "/usr/bin:/bin:/usr/sbin:/sbin";

        secrets = {
          zhipu_api_key = {
            key = "zai/zhipu_api_key";
            mode = "0400";
          };
        };
      };

      home.sessionVariables = {
        SOPS_AGE_KEY_FILE = "${config.xdg.configHome}/sops/age/keys.txt";
      };
    };
}
