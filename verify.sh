#!/bin/bash

set -e
set +o pipefail

echo "Verifying backlight"
xbacklight
