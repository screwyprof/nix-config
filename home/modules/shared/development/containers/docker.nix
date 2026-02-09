{ pkgs, lib, ... }: {
  home.packages = with pkgs; [
    docker
    #docker-compose
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
        docker stop $(docker ps -aq)
        docker rm $(docker ps -aq)
      }

      docker-rm-all() {
        docker-rm-containers
        docker network prune -f
        docker rmi -f $(docker images --filter dangling=true -qa)
        docker volume rm $(docker volume ls --filter dangling=true -q)
        docker rmi -f $(docker images -qa)
      }
    '';
  };
}
