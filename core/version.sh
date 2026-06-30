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

    local version_file="VERSION"

    if [[ ! -f "$version_file" ]]; then
        return 1
    fi

    cat "$version_file"
}
