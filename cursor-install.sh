#!/bin/bash

installCursor() {
    if ! [ -f /opt/cursor.appimage ]; then
        echo "Installing Cursor AI IDE..."

        # URLs for Cursor AppImage and Icon
        # CURSOR_URL="https://downloader.cursor.sh/linux/appImage/x64"
        ICON_URL="https://raw.githubusercontent.com/rahuljangirwork/copmany-logos/refs/heads/main/cursor.png"

        # Paths for installation
        APPIMAGE_PATH="/opt/cursor.appimage"
        ICON_PATH="/opt/cursor.png"
        DESKTOP_ENTRY_PATH="/usr/share/applications/cursor.desktop"

        # Install curl if not installed
        if ! command -v curl &> /dev/null; then
            echo "curl is not installed. Installing..."
            sudo apt-get update
            sudo apt-get install -y curl
        fi

        # Check if jq is installed
        if ! command -v jq &> /dev/null
        then
            echo "jq could not be found. Please install it (e.g., sudo apt install jq)."
            exit 1
        fi

        TEMP_DIR=$(mktemp -d)
        cd "$TEMP_DIR"

        echo "Verificando a versão mais recente do Cursor..."
        if ! DOWNLOAD_INFO=$(curl -s \
            -H "Accept: */*" \
            -H "Accept-Language: pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7" \
            -H "Priority: u=1, i" \
            -H "Sec-Ch-Ua: \"Not)A;Brand\";v=\"8\", \"Chromium\";v=\"138\", \"Google Chrome\";v=\"138\"" \
            -H "Sec-Ch-Ua-Arch: \"x86\"" \
            -H "Sec-Ch-Ua-Bitness: \"64\"" \
            -H "Sec-Ch-Ua-Mobile: ?0" \
            -H "Sec-Ch-Ua-Platform: \"Linux\"" \
            -H "Sec-Ch-Ua-Platform-Version: \"6.14.0\"" \
            -H "Sec-Fetch-Dest: empty" \
            -H "Sec-Fetch-Mode: cors" \
            -H "Sec-Fetch-Site: same-origin" \
            -H "Referer: https://cursor.com/downloads" \
            -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
            "https://cursor.com/api/download?platform=linux-x64&releaseTrack=stable"); then
            echo "Erro: Falha ao obter informações de download"
            exit 1
        fi

        echo "Download Info: $DOWNLOAD_INFO"
        DOWNLOAD_URL=$(echo "$DOWNLOAD_INFO" | jq -r '.downloadUrl')
        VERSION=$(echo "$DOWNLOAD_INFO" | jq -r '.version')

        if [ -z "$DOWNLOAD_URL" ] || [ -z "$VERSION" ]; then
            echo "Erro: Falha ao analisar informações de download"
            exit 1
        fi

        # Download Cursor AppImage
        echo "Baixando Cursor versão ${VERSION}..."
        sudo curl -L "$DOWNLOAD_URL" -o $APPIMAGE_PATH
        sudo chmod +x $APPIMAGE_PATH

        # Download Cursor icon
        echo "Downloading Cursor icon..."
        sudo curl -L $ICON_URL -o $ICON_PATH

        # Create a .desktop entry for Cursor
        echo "Creating .desktop entry for Cursor..."
        sudo bash -c "cat > $DESKTOP_ENTRY_PATH" <<EOL
[Desktop Entry]
Name=Cursor AI IDE
Exec=$APPIMAGE_PATH
Icon=$ICON_PATH
Type=Application
Categories=Development;
EOL

        echo "Cursor AI IDE installation complete. You can find it in your application menu."
        echo "Instalação concluída! Você já pode executar o Cursor (versão ${VERSION})"

        # Limpeza
        cd /
        sudo rm -rf "$TEMP_DIR"
    else
        echo "Cursor AI IDE is already installed."
    fi
}

installCursor