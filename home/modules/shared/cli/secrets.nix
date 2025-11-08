{ config, lib, pkgs, ... }:
{
  home.packages = with pkgs; [
    age # Modern encryption tool
    sops # Secrets management
  ];

  # Keep the directory; useful for your sops/age keys
  #home.file."${config.xdg.configHome}/sops/age/.keep".text = "";

  # User-level secrets management with sops-nix
  sops = {
    # Location of the private key that is used to decrypt the secrets
    # (generated with: age-keygen -o ~/.config/sops/age/keys.txt )
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

    # location of the file(s) containing the encrypted secrets
    defaultSopsFile = ../../../../secrets/secrets.yaml;

    secrets = {
      # Define which secrets to make available to this user
      zhipu_api_key = {
        #sopsFile = ../../../../secrets/secrets.yaml;
        key = "zai/zhipu_api_key";
        #path = "${config.xdg.stateHome}/sops-nix/secrets/zhipu_api_key";
        mode = "0400";
      };
    };
  };

  # Set environment variable for sops to find our age key
  # If you run CLIs manually and want sops CLI to work without setting this var every time.
  home.sessionVariables = {
    SOPS_AGE_KEY_FILE = "${config.xdg.configHome}/sops/age/keys.txt";
  };
}
