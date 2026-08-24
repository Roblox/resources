#!/bin/sh

set -e

dir="$1"
status=0

for file in $(find "$dir" -name '*.luau'); do
	line1=$(sed -n '1p' "$file")
	line2=$(sed -n '2p' "$file")

	if [ "$line1" != "-- Copyright (c) 2026 Roblox Corporation" ] || [ "$line2" != "-- SPDX-License-Identifier: MIT" ]; then
		echo "Missing or incorrect license header: $file"
		status=1
	fi
done

exit $status
