{
  flake.modules.homeManager.dev-containers =
    { pkgs, lib, ... }:
    {
      home.packages = with pkgs; [
        docker
        docker-credential-helpers
      ];

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
