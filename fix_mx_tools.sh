#!/bin/bash

# Script to fix MX Tools Polkit issues in Chrome Remote Desktop / Debian sessions.
# This creates a rule that allows users in the 'sudo' group to run MX tools
# without being blocked by missing authentication dialogs in remote sessions.

RULE_PATH="/etc/polkit-1/rules.d/99-mx-tools.rules"
RULE_CONTENT='polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.mxlinux.pkexec.") == 0 &&
        subject.isInGroup("sudo")) {
        return polkit.Result.YES;
    }
});'

echo "Applying MX Tools Polkit fix..."

if [ "$EUID" -ne 0 ]; then
  echo "This script requires sudo privileges to write to $RULE_PATH"
  echo "$RULE_CONTENT" | sudo tee "$RULE_PATH" > /dev/null
  sudo chmod 644 "$RULE_PATH"
else
  echo "$RULE_CONTENT" > "$RULE_PATH"
  chmod 644 "$RULE_PATH"
fi

echo "Fix applied successfully to $RULE_PATH"
echo "MX tools should now work without admin privilege errors."
