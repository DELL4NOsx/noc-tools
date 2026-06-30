#!/usr/bin/env bash

###############################################################################
# Project:
#   NOC Tools
#
# File:
#   bootstrap.sh
#
# Description:
#   Initializes the NOC Tools core.
#
# Author:
#   Dellanno Braga
#
# License:
#   GPLv3
###############################################################################

# =============================================================================
# Project Directories
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# =============================================================================
# Core Components
# =============================================================================

# shellcheck source=core/banner.sh
source "$PROJECT_ROOT/core/banner.sh"

# shellcheck source=core/version.sh
source "$PROJECT_ROOT/core/version.sh"
