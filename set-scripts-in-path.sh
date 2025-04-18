#!/bin/bash

# Script: set-scripts-in-path.sh
# Descrição: Este script configura o diretório ~/scripts no PATH do sistema.
# Adiciona uma entrada no arquivo .bashrc do usuário para incluir o diretório
# de scripts pessoais no PATH, permitindo executar os scripts de qualquer lugar.
#
# Funcionalidades:
# - Verifica se o diretório ~/scripts existe
# - Verifica se a configuração já existe no .bashrc
# - Adiciona a configuração de forma segura
# - Fornece instruções para aplicar as alterações

# Verifica se o diretório scripts existe
if [ ! -d "$HOME/scripts" ]; then
    echo "Erro: O diretório ~/scripts não existe."
    echo "Por favor, crie o diretório antes de executar este script."
    exit 1
fi

# Linha a ser adicionada ao .bashrc
SCRIPTS_PATH='export PATH="$HOME/scripts:$PATH"'

# Verifica se a linha já existe no .bashrc
if ! grep -Fxq "$SCRIPTS_PATH" "$HOME/.bashrc"; then
    echo "Adicionando ~/scripts ao PATH no .bashrc..."
    echo "" >> "$HOME/.bashrc"
    echo "# Adiciona diretório de scripts pessoais ao PATH" >> "$HOME/.bashrc"
    echo "$SCRIPTS_PATH" >> "$HOME/.bashrc"
    echo "Configuração concluída! O diretório ~/scripts foi adicionado ao PATH."
    echo "Para aplicar as alterações, execute: source ~/.bashrc"
else
    echo "O diretório ~/scripts já está configurado no PATH."
fi