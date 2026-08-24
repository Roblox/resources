#!/bin/sh

set -e

curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
# Installed without trust check since this is running on a CI machine (we've already trusted and installed the tools on our local device)
~/.rokit/bin/rokit install --no-trust-check