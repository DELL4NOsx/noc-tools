#!/usr/bin/env bash

###############################################################################
# Project:
#   NOC Tools
#
# File:
#   noc.sh
#
# Description:
#   Entry point of the NOC Tools application.
#
# Author:
#   Dellanno Braga
#
# License:
#   GPLv3
###############################################################################

# =============================================================================
# Bootstrap
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=core/bootstrap.sh
source "$SCRIPT_DIR/core/bootstrap.sh"

# =============================================================================
# Main
# =============================================================================

print_banner

if ! VERSION="$(get_version)"; then
    echo "Erro: não foi possível ler o arquivo VERSION."
    exit 1
fi

echo
echo "Version : $VERSION"
echo
echo "Uma ferramenta para quem procura soluções e conhecimento."
echo
echo "Comandos disponíveis:"
echo
echo "  help      Exibe a ajuda"
echo "  version   Mostra a versão"
echo "  about     Sobre o projeto"
echo
echo "Projeto em desenvolvimento."
echo "Licença: GPLv3"
