#!/usr/bin/env bash

###############################################################################
# Project:
#   NOC Tools
#
# File:
#   version.sh
#
# Description:
#   Reads the current project version.
#
# Author:
#   Dellanno Braga
#
# License:
#   GPLv3
###############################################################################

get_version() {

    local version_file="$PROJECT_ROOT/VERSION"

    if [[ ! -f "$version_file" || ! -r "$version_file" ]]; then
        return 1
    fi

    cat "$version_file"
}
