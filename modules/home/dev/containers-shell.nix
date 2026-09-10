# dev-containers-shell ASPECT — the docker/compose SHELL UX, and nothing else: aliases + two helper
# functions. No packages, deliberately.
#
# Split out of `dev-containers` because the two halves have different suppliers. On a Mac the client
# comes from `home.packages` (that module). Inside a devbox cage it comes from the cage's own container
# capability, where `docker` is a wrapper over rootless podman plus a compose argv router — so a
# home-manager `pkgs.docker` there would land earlier on PATH than the capability's shim and give the
# occupant a Moby client with no daemon to reach. Same aliases, different provider; only the UX is
# portable, so only the UX is shared.
{
  flake.modules.homeManager.dev-containers-shell =
    { lib, ... }:
    {
      programs.zsh = {
        shellAliases = {
          dcp = "docker compose pull";
          dcps = "docker compose ps";
          dcu = "docker compose up -d";
          dcd = "docker compose down --remove-orphans --volumes";
          dcr = "docker compose restart";
          dclf = "docker compose logs -f";
          dlf = "docker logs -f";
          dcuf = "docker compose up --build --force-recreate --no-deps -d";
          dcs = "docker compose stop";
          drac = "docker container prune";
          drav = "docker volume prune";
          dra = "docker system prune --volumes";
        };

        initContent = lib.mkAfter ''
          # Docker helper functions
          docker-rm-containers() {
            local ids=$(docker ps -aq)
            [[ -n "$ids" ]] && docker stop $ids && docker rm $ids
          }

          docker-rm-all() {
            docker-rm-containers
            docker network prune -f
            local dangling=$(docker images --filter dangling=true -qa)
            [[ -n "$dangling" ]] && docker rmi -f $dangling
            local volumes=$(docker volume ls --filter dangling=true -q)
            [[ -n "$volumes" ]] && docker volume rm $volumes
            local all_images=$(docker images -qa)
            [[ -n "$all_images" ]] && docker rmi -f $all_images
          }
        '';
      };
    };
}
