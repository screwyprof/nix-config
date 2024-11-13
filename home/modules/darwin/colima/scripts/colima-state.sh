#!/bin/sh

PROFILE=${1:-docker}
AGENT_PLIST="${HOME}/Library/LaunchAgents/com.github.colima.nix.plist"
WRAPPER="${HOME}/.local/bin/colima-wrapper.sh"

STATE=$($WRAPPER "$PROFILE" status)
COLIMA_RUNNING=$(echo "$STATE" | tail -n1 | cut -d: -f1)
AGENT_EXISTS=$(echo "$STATE" | tail -n1 | cut -d: -f2)
AGENT_LOADED=$(echo "$STATE" | tail -n1 | cut -d: -f3)

if [ $COLIMA_RUNNING -eq 1 ]; then
    if [ $AGENT_EXISTS -eq 0 ] && [ $AGENT_LOADED -eq 1 ]; then
        echo "Case 3: Colima running, agent loaded but no plist"
        $WRAPPER "$PROFILE" stop
        /bin/launchctl bootout gui/$UID/com.github.colima.nix || true
    elif [ $AGENT_EXISTS -eq 0 ] && [ $AGENT_LOADED -eq 0 ]; then
        echo "Case 4: Colima running, no agent"
        $WRAPPER "$PROFILE" stop
    fi
else
    if [ $AGENT_LOADED -eq 1 ]; then
        echo "Case 5: Colima not running but agent loaded"
        /bin/launchctl bootout gui/$UID/com.github.colima.nix || true
    elif [ $AGENT_EXISTS -eq 1 ] && [ $AGENT_LOADED -eq 0 ]; then
        echo "Case 6: Agent exists but not loaded"
        /bin/launchctl bootstrap gui/$UID "$AGENT_PLIST"
    fi
fi 