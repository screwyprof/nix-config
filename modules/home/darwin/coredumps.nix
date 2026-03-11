{
  flake.modules.homeManager.darwin-coredumps =
    { config, lib, ... }:
    let
      dumpsDir = "${config.xdg.stateHome}/coredump";
    in
    {
      # Create dumps directory
      home.activation.createDumpsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p ${dumpsDir}
      '';

      # Set core dump location on activation (requires sudo)
      home.activation.setCoredumpPath = lib.hm.dag.entryAfter [ "createDumpsDir" ] ''
        verboseEcho "Setting core dump path to ${dumpsDir}"
        run sudo sysctl -w kern.corefile=${dumpsDir}/%N.%P.core
      '';

      # Cleanup old core dumps weekly
      launchd.agents.cleandumps = {
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
