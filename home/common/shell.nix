{ pkgs, ... }: {
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [
        "aws"
        "git"
        "gitfast"
        "alias-finder"
        "command-not-found"
        "copyfile"
        "direnv"
        "dotenv"
        "extract"
        "golang"
        "kubectl"
        "npm"
        "macos"
        "rust"
        "sudo"
        "yarn"
      ];
      custom = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k";
      theme = "powerlevel10k";
    };

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "powerlevel10k-config";
        src = ./p10k-config;
        file = "p10k.zsh";
      }
    ];

    initExtra = ''
      # Powerlevel10k instant prompt
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi

      # Custom ZSH configurations
      setopt AUTO_CD
      setopt EXTENDED_GLOB
      
      # Docker helpers
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

      # Environment variables
      export TERM=xterm-256color
      export EDITOR=vim
      export K9S_EDITOR=vim
      export GOPATH=$HOME/go
      export PATH=$GOPATH/bin:$PATH
      # Source p10k config
      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
    '';

    shellAliases = {
      # Basic
      ll = "ls -la";
      ".." = "cd ..";
      "..." = "cd ../..";
      
      # Docker
      dcp = "docker-compose pull";
      dcps = "docker-compose ps";
      dcu = "docker-compose up -d";
      dcd = "docker-compose down --remove-orphans --volumes";
      dcr = "docker-compose restart";
      dclf = "docker-compose logs -f";
      dlf = "docker logs -f";
      
      # Git
      fakecommit = "git commit --amend --no-edit && git push -f";
      cherrymaster = "git cherry -v master | cut -d ' ' -f3-";
      rmbranches = "git branch | grep -v 'master' | grep -v 'main' | xargs git branch -D";
      
      # Nix
      nix-rebuild-mac = "darwin-rebuild switch --flake .#mac";
    };
  };
} 