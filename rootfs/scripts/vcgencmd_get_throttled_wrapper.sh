#!/usr/bin/env bash

# Fix for issue #41 (https://github.com/mikenye/docker-adsbexchange/issues/41)

# Set correct path
PATH=$PATH:/opt/vc/bin

# Check if 'vcgencmd' exists
if which vcgencmd > /dev/null; then
  # Attempt to call 'vcgencmd get_throttled'.
  VCGENCMD_GET_THROTTLED=$(vcgencmd get_throttled 2>&1)
  if [[ "$?" -ne 0 ]]; then
    # If the command works (ie, user is on RPi and has forwarded the /dev/vhci into the container), then use that output.
    echo "$VCGENCMD_GET_THROTTLED"
  else
    # If the exit status of vcgencmd is not 0, then spoof the output with throttled=0x0
    echo "throttled=0x0"
  fi
else
  # If 'vcgencmd' doesn't exist, then spoof the output with throttled=0x0
  echo "throttled=0x0"
fi
