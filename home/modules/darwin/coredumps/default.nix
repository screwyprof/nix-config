{ config, lib, ... }:

let
  dumpsDir = "${config.xdg.stateHome}/coredump";
in
{
  # Create dumps directory
  home.activation.createDumpsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${dumpsDir}
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
          "sysctl -w kern.corefile=${dumpsDir}/%N.%P.core"
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
          "find ${dumpsDir} -name '*.core' -mtime +7 -delete"
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
