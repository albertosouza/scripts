#!/bin/bash

# Script: antigravity-update.sh
# Descrição: Atualiza uma instalação existente do Google Antigravity (Hub e/ou IDE) no Ubuntu.
# Autor: Antigravity AI Assistant
# Data: 2026-05-22

# Cores para saída formatada
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Função para exibir o cabeçalho
show_header() {
    clear
    echo -e "${BLUE}${BOLD}================================================================${NC}"
    echo -e "${CYAN}${BOLD}         Atualizador do Google Antigravity (Hub e IDE)          ${NC}"
    echo -e "${BLUE}${BOLD}================================================================${NC}"
    echo ""
}

# Verificar privilégios de root
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Solicitando acesso sudo para atualizar o Google Antigravity...${NC}"
    exec sudo "$0" "$@"
    exit $?
fi

# Obter o usuário real e seu diretório home
REAL_USER=$SUDO_USER
if [ -z "$REAL_USER" ]; then
    REAL_USER=$(whoami)
fi
USER_HOME=$(eval echo ~$REAL_USER)

show_header

# 1. Verificar dependências necessárias
echo -e "${BLUE}[1/5] Verificando dependências do sistema...${NC}"
for cmd in curl jq tar; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${YELLOW}Instalando dependência ausente: $cmd...${NC}"
        apt-get update -y && apt-get install -y $cmd
    else
        echo -e "  [${GREEN}✓${NC}] $cmd está instalado."
    fi
done
echo ""

# 2. Verificar o que está instalado no sistema
echo -e "${BLUE}[2/5] Verificando instalações ativas do Google Antigravity...${NC}"
HAS_HUB=false
HAS_IDE=false

if [ -d "/opt/antigravity" ]; then
    HAS_HUB=true
    echo -e "  [${GREEN}✓${NC}] Google Antigravity Hub detectado em: /opt/antigravity"
fi

if [ -d "/opt/antigravity-ide" ]; then
    HAS_IDE=true
    echo -e "  [${GREEN}✓${NC}] Google Antigravity IDE detectada em: /opt/antigravity-ide"
fi

if [ "$HAS_HUB" = false ] && [ "$HAS_IDE" = false ]; then
    echo -e "  [${RED}✗${NC}] Nenhuma instalação do Google Antigravity foi encontrada."
    echo -e "${YELLOW}Por favor, utilize o script de instalação primeiro: ${CYAN}./antigravity-install.sh${NC}"
    exit 1
fi
echo ""

# 3. Detectar arquitetura
echo -e "${BLUE}[3/5] Detectando arquitetura do processador...${NC}"
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    PLATFORM_HUB="linux-x64"
    PLATFORM_IDE="linux-x64"
    echo -e "  [${GREEN}✓${NC}] Arquitetura detectada: x86_64 (Linux x64)"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    PLATFORM_HUB="linux-arm"
    PLATFORM_IDE="linux-arm"
    echo -e "  [${GREEN}✓${NC}] Arquitetura detectada: ARM64 (Linux ARM64)"
else
    echo -e "  [${RED}✗${NC}] Arquitetura não suportada: $ARCH"
    exit 1
fi
echo ""

# 4. Consultar versões mais recentes
echo -e "${BLUE}[4/5] Consultando versões estáveis mais recentes...${NC}"

# Buscar dados do Antigravity Hub
HUB_RELEASE_INFO=$(curl -s "https://antigravity-hub-auto-updater-974169037036.us-central1.run.app/releases")
HUB_VERSION=$(echo "$HUB_RELEASE_INFO" | jq -r '.[0].version')
HUB_EXEC_ID=$(echo "$HUB_RELEASE_INFO" | jq -r '.[0].execution_id')

# Buscar dados do Antigravity IDE
IDE_RELEASE_INFO=$(curl -s "https://antigravity-ide-auto-updater-974169037036.us-central1.run.app/releases")
IDE_VERSION=$(echo "$IDE_RELEASE_INFO" | jq -r '.[0].version')
IDE_EXEC_ID=$(echo "$IDE_RELEASE_INFO" | jq -r '.[0].execution_id')

if [ -z "$HUB_VERSION" ] || [ -z "$IDE_VERSION" ]; then
    echo -e "  [${RED}✗${NC}] Erro ao buscar informações de versão. Verifique sua conexão com a internet."
    exit 1
fi

echo -e "  [${GREEN}✓${NC}] Google Antigravity Hub (CLI): versão ${GREEN}$HUB_VERSION${NC} disponível."
echo -e "  [${GREEN}✓${NC}] Google Antigravity IDE: versão ${GREEN}$IDE_VERSION${NC} disponível."
echo ""

# Selecionar o que atualizar de acordo com o que está instalado
UPDATE_HUB=false
UPDATE_IDE=false

if [ "$HAS_HUB" = true ] && [ "$HAS_IDE" = true ]; then
    echo -e "${BLUE}[5/5] Selecione o que deseja atualizar:${NC}"
    echo -e "  ${BOLD}1)${NC} Google Antigravity Hub"
    echo -e "  ${BOLD}2)${NC} Google Antigravity IDE"
    echo -e "  ${BOLD}3)${NC} Ambos"
    echo -e "  ${BOLD}4)${NC} Cancelar"
    echo -n "Escolha uma opção [1-4]: "
    read -r OPTION

    case $OPTION in
        1) UPDATE_HUB=true ;;
        2) UPDATE_IDE=true ;;
        3)
            UPDATE_HUB=true
            UPDATE_IDE=true
            ;;
        *)
            echo -e "${YELLOW}Atualização cancelada pelo usuário.${NC}"
            exit 0
            ;;
    esac
elif [ "$HAS_HUB" = true ]; then
    echo -n "Deseja atualizar o Google Antigravity Hub para a versão $HUB_VERSION? (y/N): "
    read -r RESPONSE
    if [[ "$RESPONSE" =~ ^[Yy]$ ]]; then
        UPDATE_HUB=true
    else
        echo -e "${YELLOW}Atualização cancelada.${NC}"
        exit 0
    fi
elif [ "$HAS_IDE" = true ]; then
    echo -n "Deseja atualizar a Google Antigravity IDE para a versão $IDE_VERSION? (y/N): "
    read -r RESPONSE
    if [[ "$RESPONSE" =~ ^[Yy]$ ]]; then
        UPDATE_IDE=true
    else
        echo -e "${YELLOW}Atualização cancelada.${NC}"
        exit 0
    fi
fi

TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR" || exit 1

# Flag para rastrear sucessos
HUB_UPDATED=false
IDE_UPDATED=false

# Função para atualizar o Hub
update_hub() {
    local url="https://storage.googleapis.com/antigravity-public/antigravity-hub/${HUB_VERSION}-${HUB_EXEC_ID}/${PLATFORM_HUB}/Antigravity.tar.gz"
    echo -e "\n${CYAN}Baixando Google Antigravity Hub (${HUB_VERSION})...${NC}"
    
    if ! curl -L "$url" -o antigravity-hub.tar.gz; then
        echo -e "${RED}Erro ao baixar Antigravity Hub de: $url${NC}"
        return 1
    fi
    
    echo -e "${CYAN}Extraindo Antigravity Hub...${NC}"
    tar -xzf antigravity-hub.tar.gz
    
    local folder_name="Antigravity-x64"
    if [ "$PLATFORM_HUB" = "linux-arm" ]; then
        folder_name="Antigravity-arm"
    fi
    
    if [ ! -d "$folder_name" ]; then
        folder_name=$(find . -maxdepth 1 -type d -name "Antigravity*" | head -n 1)
        folder_name=${folder_name#./}
    fi
    
    # Criar Backup da versão existente
    echo -e "${CYAN}Criando backup da versão antiga do Hub...${NC}"
    rm -rf /opt/antigravity.bak
    if [ -d "/opt/antigravity" ]; then
        mv /opt/antigravity /opt/antigravity.bak
    fi
    
    echo -e "${CYAN}Instalando nova versão em /opt/antigravity...${NC}"
    if ! mv "$folder_name" /opt/antigravity; then
        echo -e "${RED}Erro ao mover nova versão. Restaurando backup...${NC}"
        if [ -d "/opt/antigravity.bak" ]; then
            mv /opt/antigravity.bak /opt/antigravity
        fi
        return 1
    fi
    
    # Configurar sandbox do chrome
    if [ -f "/opt/antigravity/chrome-sandbox" ]; then
        chown root:root /opt/antigravity/chrome-sandbox
        chmod 4755 /opt/antigravity/chrome-sandbox
    fi
    
    # Criar link simbólico
    echo -e "${CYAN}Verificando link simbólico em /usr/local/bin/antigravity...${NC}"
    ln -sf /opt/antigravity/antigravity /usr/local/bin/antigravity
    
    # Baixar ícone
    echo -e "${CYAN}Configurando ícone do aplicativo...${NC}"
    mkdir -p /usr/share/pixmaps
    curl -sL "https://antigravity.google/assets/image/antigravity-logo.png" -o /usr/share/pixmaps/antigravity.png
    
    # Criar atalho Desktop (.desktop)
    echo -e "${CYAN}Criando/Atualizando atalho no menu do sistema...${NC}"
    cat > /usr/share/applications/antigravity.desktop << EOL
[Desktop Entry]
Name=Google Antigravity Hub
Comment=Google Antigravity Agent Platform
Exec=/opt/antigravity/antigravity %U
Icon=/usr/share/pixmaps/antigravity.png
Terminal=false
Type=Application
Categories=Development;IDE;
StartupWMClass=antigravity
EOL

    echo -e "${GREEN}✓ Google Antigravity Hub atualizado com sucesso!${NC}"
    HUB_UPDATED=true
}

# Função para atualizar a IDE
update_ide() {
    local url="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/${IDE_VERSION}-${IDE_EXEC_ID}/${PLATFORM_IDE}/Antigravity%20IDE.tar.gz"
    echo -e "\n${CYAN}Baixando Google Antigravity IDE (${IDE_VERSION})...${NC}"
    
    if ! curl -L "$url" -o antigravity-ide.tar.gz; then
        echo -e "${RED}Erro ao baixar Antigravity IDE de: $url${NC}"
        return 1
    fi
    
    echo -e "${CYAN}Extraindo Antigravity IDE...${NC}"
    tar -xzf antigravity-ide.tar.gz
    
    local folder_name="Antigravity IDE"
    if [ ! -d "$folder_name" ]; then
        folder_name=$(find . -maxdepth 1 -type d -name "Antigravity*IDE*" -o -name "*IDE" | head -n 1)
        folder_name=${folder_name#./}
    fi
    
    # Criar Backup da versão existente
    echo -e "${CYAN}Criando backup da versão antiga da IDE...${NC}"
    rm -rf /opt/antigravity-ide.bak
    if [ -d "/opt/antigravity-ide" ]; then
        mv /opt/antigravity-ide /opt/antigravity-ide.bak
    fi
    
    echo -e "${CYAN}Instalando nova versão em /opt/antigravity-ide...${NC}"
    if ! mv "$folder_name" /opt/antigravity-ide; then
        echo -e "${RED}Erro ao mover nova versão. Restaurando backup...${NC}"
        if [ -d "/opt/antigravity-ide.bak" ]; then
            mv /opt/antigravity-ide.bak /opt/antigravity-ide
        fi
        return 1
    fi
    
    # Configurar sandbox do chrome
    if [ -f "/opt/antigravity-ide/chrome-sandbox" ]; then
        chown root:root /opt/antigravity-ide/chrome-sandbox
        chmod 4755 /opt/antigravity-ide/chrome-sandbox
    fi
    
    # Criar link simbólico
    echo -e "${CYAN}Verificando link simbólico em /usr/local/bin/antigravity-ide...${NC}"
    ln -sf "/opt/antigravity-ide/antigravity-ide" /usr/local/bin/antigravity-ide
    
    # Baixar ícone
    echo -e "${CYAN}Configurando ícone do aplicativo...${NC}"
    mkdir -p /usr/share/pixmaps
    curl -sL "https://antigravity.google/assets/image/antigravity-logo.png" -o /usr/share/pixmaps/antigravity-ide.png
    
    # Criar atalho Desktop (.desktop)
    echo -e "${CYAN}Criando/Atualizando atalho no menu do sistema...${NC}"
    cat > /usr/share/applications/antigravity-ide.desktop << EOL
[Desktop Entry]
Name=Google Antigravity IDE
Comment=Google Antigravity Agent-First IDE
Exec="/opt/antigravity-ide/antigravity-ide" %U
Icon=/usr/share/pixmaps/antigravity-ide.png
Terminal=false
Type=Application
Categories=Development;IDE;
StartupWMClass=antigravity-ide
EOL

    echo -e "${GREEN}✓ Google Antigravity IDE atualizada com sucesso!${NC}"
    IDE_UPDATED=true
}

# Executar as atualizações selecionadas
if [ "$UPDATE_HUB" = true ]; then
    update_hub
fi

if [ "$UPDATE_IDE" = true ]; then
    update_ide
fi

# Configurações Finais de Ambiente
if [ "$HUB_UPDATED" = true ] || [ "$IDE_UPDATED" = true ]; then
    if [ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ]; then
        echo -e "\n${CYAN}Verificando permissões das pastas locais do usuário ($REAL_USER)...${NC}"
        mkdir -p "$USER_HOME/.antigravity" "$USER_HOME/.antigravity-ide" "$USER_HOME/.antigravitycli"
        chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/.antigravity" "$USER_HOME/.antigravity-ide" "$USER_HOME/.antigravitycli"
    fi
fi

# Limpeza do diretório temporário
cd /
rm -rf "$TEMP_DIR"

# Cabeçalho de conclusão
echo ""
echo -e "${GREEN}${BOLD}================================================================${NC}"
echo -e "${GREEN}${BOLD}             Atualização concluída com sucesso!                ${NC}"
echo -e "${GREEN}${BOLD}================================================================${NC}"
echo ""

if [ "$HUB_UPDATED" = true ]; then
    echo -e "  * Google Antigravity Hub atualizado para a versão ${GREEN}$HUB_VERSION${NC}"
    echo -e "    Backup antigo salvo em: /opt/antigravity.bak"
fi

if [ "$IDE_UPDATED" = true ]; then
    echo -e "  * Google Antigravity IDE atualizada para a versão ${GREEN}$IDE_VERSION${NC}"
    echo -e "    Backup antigo salva em: /opt/antigravity-ide.bak"
fi

echo ""
echo -e "Para remover os backups caso tudo esteja funcionando perfeitamente, execute:"
if [ "$HUB_UPDATED" = true ]; then
    echo -e "  ${CYAN}sudo rm -rf /opt/antigravity.bak${NC}"
fi
if [ "$IDE_UPDATED" = true ]; then
    echo -e "  ${CYAN}sudo rm -rf /opt/antigravity-ide.bak${NC}"
fi
echo ""
