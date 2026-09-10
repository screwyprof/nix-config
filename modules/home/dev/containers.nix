# dev-containers ASPECT — a container CLIENT plus its shell UX, for a host that must supply its own
# engine tooling (the Mac: `lima` drives the VM, `docker` talks to it).
#
# The UX half lives in `dev-containers-shell` and is imported here, so this module's consumers are
# unchanged. A host whose engine is supplied FOR it — a devbox cage — imports that module alone and
# must not import this one; see the note there.
{ config, ... }:
{
  flake.modules.homeManager.dev-containers =
    { pkgs, ... }:
    {
      imports = [ config.flake.modules.homeManager.dev-containers-shell ];

      home.packages = with pkgs; [
        lima
        docker
        docker-credential-helpers
      ];
    };
}
