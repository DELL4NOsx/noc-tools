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

CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$CORE_DIR")"

# =============================================================================
# Core Components
# =============================================================================

# shellcheck source=core/banner.sh
source "$PROJECT_ROOT/core/banner.sh" || return 1

# shellcheck source=core/version.sh
source "$PROJECT_ROOT/core/version.sh" || return 1
