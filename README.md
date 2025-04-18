# Scripts de Utilidades para Linux do Alberto

Uma coleção de scripts úteis para Linux, incluindo instalação e atualização do editor Cursor e gerenciamento de PATH.

## Instalação

1. Clone este repositório na pasta `~/scripts`:
```bash
git clone https://github.com/seu-usuario/linux-scripts.git ~/scripts
```

2. Configure o diretório de scripts no PATH do sistema:
```bash
cd ~/scripts
chmod +x *.sh
./set-scripts-in-path.sh
source ~/.bashrc
```

## Scripts Disponíveis

### cursor-install.sh
Instala o editor Cursor como AppImage no sistema.

**Uso:**
```bash
cursor-install.sh
```

**Funcionalidades:**
- Baixa a última versão do Cursor
- Instala em /opt/cursor.appimage
- Cria atalho no menu de aplicativos
- Requer privilégios sudo (solicitados automaticamente)

### cursor-update.sh
Atualiza uma instalação existente do Cursor.

**Uso:**
```bash
cursor-update.sh
```

**Funcionalidades:**
- Baixa a última versão do Cursor
- Faz backup da versão anterior
- Atualiza mantendo configurações
- Requer privilégios sudo (solicitados automaticamente)

### set-scripts-in-path.sh
Configura o diretório ~/scripts no PATH do sistema.

**Uso:**
```bash
set-scripts-in-path.sh
```

**Funcionalidades:**
- Adiciona ~/scripts ao PATH via .bashrc
- Verifica instalação existente
- Fornece instruções de ativação

## Exemplos de Uso

1. Instalação completa do ambiente:
```bash
# Clone o repositório
git clone https://github.com/seu-usuario/linux-scripts.git ~/scripts

# Configure o PATH
cd ~/scripts
chmod +x *.sh
./set-scripts-in-path.sh
source ~/.bashrc

# Instale o Cursor
cursor-install.sh
```

2. Atualização do Cursor:
```bash
# Quando houver uma nova versão disponível
cursor-update.sh
```

## Requisitos

- Linux (testado em Ubuntu/Debian)
- curl
- sudo (para instalação/atualização do Cursor)
- Git (para clonar o repositório)

## Contribuindo

1. Faça um fork do repositório
2. Crie uma branch para sua feature (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -am 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Crie um Pull Request

## Links

- [Site do Alberto Souza](https://albertosouza.net)
- [Caramelo AI](https://carameloai.com)

## Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE.md) para detalhes.

Copyright (c) 2025 Alberto Souza