#!/bin/bash
# Standalone pure shell script to organize Antigravity projects.
# Uses jq and standard bash commands to parse and categorize projects.
# Paths are dynamically resolved using $HOME to support any user workspace.

PROJECTS_DIR="$HOME/.gemini/config/projects"
BACKUP_DIR="$HOME/.gemini/config/projects_backup"

# Color constants
GREEN='\033[92m'
RED='\033[91m'
NC='\033[0m' # No Color

if [ ! -d "$PROJECTS_DIR" ]; then
    echo "Erro: O diretório de projetos não existe: $PROJECTS_DIR"
    exit 1
fi

# Verify if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Erro: Este script requer 'jq' para analisar os arquivos JSON."
    echo "Por favor, instale-o com: sudo apt install jq"
    exit 1
fi

echo "=================================================="
echo "   Antigravity Projects Cleanup & Organizer (Bash)"
echo "=================================================="

# Temporary files to store lists
TMP_CLEAN_FOLDERS=$(mktemp)
TMP_PROJECTS_DATA=$(mktemp)

# Cleanup temp files on exit
trap 'rm -f "$TMP_CLEAN_FOLDERS" "$TMP_PROJECTS_DATA"' EXIT

# First Pass: Load all projects and identify clean projects
for file in "$PROJECTS_DIR"/*.json; do
    [ -e "$file" ] || continue
    filename=$(basename "$file")
    id=$(jq -r '.id // empty' "$file")
    [ -z "$id" ] && id="${filename%.json}"
    name=$(jq -r '.name // empty' "$file")
    
    # Get all resource paths, cleaning file:// scheme
    folders=$(jq -r '.projectResources.resources[] | (.folderUri // .gitFolder.folderUri) // empty' "$file" | sed 's|^file://||')
    
    # Convert folders list to a single line space-separated string
    folders_line=$(echo "$folders" | tr '\n' ' ' | xargs)
    
    # Save project data for second pass (format: filename|id|name|folders)
    echo "$filename|$id|$name|$folders_line" >> "$TMP_PROJECTS_DATA"
    
    # If the name is clean (does not start with /), save its folder paths for duplicate/nest check
    if [[ ! "$name" =~ ^/ ]]; then
        for folder in $folders; do
            echo "$folder" >> "$TMP_CLEAN_FOLDERS"
        done
    fi
done

# Second Pass: Categorize and analyze
echo ""
echo "--- PROJETOS QUE SERÃO MANTIDOS ---"
keep_count=0
delete_count=0
files_to_delete=()
reasons_to_delete=()
names_to_delete=()

while IFS='|' read -r filename id name folders; do
    [ -z "$filename" ] && continue
    
    # Check if name is clean (doesn't start with /)
    if [[ ! "$name" =~ ^/ ]]; then
        echo -e "  • ${GREEN}${name}${NC} (ID: ${id})"
        echo "    Pastas: ${folders}"
        ((keep_count++))
        continue
    fi
    
    # Replace absolute home path references with ~ for display friendliness
    display_name="${name/#$HOME/\~}"
    
    # Analyze path-based projects
    reason=""
    
    # 1. Check duplicate folder
    for folder in $folders; do
        if grep -Fxq "$folder" "$TMP_CLEAN_FOLDERS" 2>/dev/null; then
            reason="Duplicata de um projeto principal"
            break
        fi
    done
    
    # 2. Check nested or task folder
    if [ -z "$reason" ]; then
        for folder in $folders; do
            if [[ "$folder" == *".tasks/"* ]]; then
                reason="Pasta de tarefa temporária (.tasks)"
                break
            fi
            
            # Check if it starts with any folder in clean list (nested)
            while read -r clean_folder; do
                if [ -n "$clean_folder" ] && [[ "$folder" == "$clean_folder"/* ]]; then
                    reason="Subdiretório de um projeto principal"
                    break 2
                fi
            done < "$TMP_CLEAN_FOLDERS"
        done
    fi
    
    # 3. Fallback: just a general auto-generated absolute path
    if [ -z "$reason" ]; then
        reason="Caminho absoluto autogerado"
    fi
    
    # Queue for deletion
    files_to_delete+=("$filename")
    reasons_to_delete+=("$reason")
    names_to_delete+=("$display_name")
    ((delete_count++))
    
done < "$TMP_PROJECTS_DATA"

echo -e "\nTotal de projetos encontrados: $((keep_count + delete_count))"
echo -e "Projetos para manter: ${keep_count}"
echo -e "Projetos recomendados para limpeza: ${delete_count}"

if [ "$delete_count" -eq 0 ]; then
    echo -e "\nNenhum projeto autogerado ou duplicado para limpar!"
    exit 0
fi

echo ""
echo "--- PROJETOS SUGERIDOS PARA REMOÇÃO/BACKUP ---"
for ((i=0; i<delete_count; i++)); do
    idx=$((i+1))
    echo -e "  [$idx] Nome: ${RED}${names_to_delete[i]}${NC}"
    echo "      ID: ${files_to_delete[i]}"
    echo "      Motivo: ${reasons_to_delete[i]}"
done

echo "=================================================="
read -p "Deseja mover os projetos sugeridos para a pasta de backup? (s/N): " confirm

if [[ "$confirm" =~ ^[sSyY]([iImMoOsS])?$ ]]; then
    mkdir -p "$BACKUP_DIR"
    echo -e "\nCriando backup em: $BACKUP_DIR"
    
    success_count=0
    for ((i=0; i<delete_count; i++)); do
        src="$PROJECTS_DIR/${files_to_delete[i]}"
        if [ -f "$src" ]; then
            if mv "$src" "$BACKUP_DIR/"; then
                echo -e "  [OK] Mapeamento de '${names_to_delete[i]}' movido."
                ((success_count++))
            else
                echo -e "  [Erro] Falha ao mover '${names_to_delete[i]}'."
            fi
        fi
    done
    echo -e "\nSucesso! ${success_count} projetos movidos para o backup."
else
    echo -e "\nOperação cancelada pelo usuário."
fi
