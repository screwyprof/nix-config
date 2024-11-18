{ config, lib, ... }:

let
  homeDir = config.home.homeDirectory;
in
{
  # Create dumps directory
  home.activation.createDumpsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p ${homeDir}/.local/dumps
  '';

  # Configure core dump location and cleanup via launchd agents (user-specific)
  launchd.agents = {
    coredump = {
      enable = true;
      config = {
        Label = "com.user.coredump";
        ProgramArguments = [
          "/bin/sh"
          "-c"
          "sysctl -w kern.corefile=${homeDir}/.local/dumps/%N.%P.core"
        ];
        RunAtLoad = true;
      };
    };

    cleandumps = {
      enable = true;
      config = {
        Label = "com.user.cleandumps";
        ProgramArguments = [
          "/bin/sh"
          "-c"
          "find ${homeDir}/.local/dumps -name '*.core' -mtime +7 -delete"
        ];
        StartCalendarInterval = [
          {
            Hour = 21;
            Minute = 0;
          }
        ];
      };
    };
  };
}
