{
  # From the store, not fetched by zimfw at shell start: an interrupted fetch leaves a module dir holding
  # only headers, which zimfw then counts as installed — silently, for good.
  flake.lib.zimfwModule =
    pkgs: name:
    let
      pins = {
        "zimfw/environment" = {
          rev = "d4bceaa3da89cd819843334dba1a5bf7dc137e14";
          hash = "sha256-B8Cki4uCcSce0xewZ91P9wCpA5+x/AlT1IwC+HVs6OI=";
        };
        "zimfw/input" = {
          rev = "bdec2b372f8bd16a072d30ebc447a22dad52cfb4";
          hash = "sha256-/tWks6oFH6/LK8u9SxsZIJ9uAonJ2T6l91BflDwog80=";
        };
        "zimfw/utility" = {
          rev = "e1d1c23f578420e285cbea41dbd5cef75b35ca5b";
          hash = "sha256-2V3GYtfEtHwU8ba7pd9gQykUjp+yI0UBmxSOnHQdXNM=";
        };
        "zimfw/git" = {
          rev = "7d38eb4d9e595241bbbcdd62f836d1ee668317fc";
          hash = "sha256-9GQYpvZAKyZwxuT+RFHxNWGapxc/5w9/+TExQZhIDWk=";
        };
        "zimfw/exa" = {
          rev = "bb677b7f79a52774940fd9ca80431ee98635ef41";
          hash = "sha256-HhLwor4Br/kfDfthfn1fBU/3ULQASUhuDAbqmX5SnAI=";
        };
      };
      owner = builtins.dirOf name;
      repo = builtins.baseNameOf name;
    in
    "${pkgs.fetchFromGitHub ({ inherit owner repo; } // pins.${name})}";
}
