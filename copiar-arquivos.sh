#!/bin/bash

# Script para copiar arquivos do projeto para /opt/docmanage
# Execute: bash scripts/copiar-arquivos.sh /caminho/para/seus/arquivos

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  COPIAR ARQUIVOS DO PROJETO   ${NC}"
echo -e "${BLUE}================================${NC}"
echo

# Verificar parâmetro
if [ -z "$1" ]; then
    echo -e "${RED}Erro: Especifique o diretório de origem${NC}"
    echo -e "${YELLOW}Uso: bash scripts/copiar-arquivos.sh /caminho/para/seus/arquivos${NC}"
    echo
    echo -e "${BLUE}Exemplos:${NC}"
    echo -e "bash scripts/copiar-arquivos.sh ~/Downloads/docmanage"
    echo -e "bash scripts/copiar-arquivos.sh /home/usuario/projeto-docmanage"
    exit 1
fi

SOURCE_DIR="$1"
TARGET_DIR="/opt/docmanage"

# Verificar se diretório de origem existe
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}Erro: Diretório de origem não encontrado: $SOURCE_DIR${NC}"
    exit 1
fi

# Verificar se tem arquivos essenciais
if [ ! -f "$SOURCE_DIR/package.json" ]; then
    echo -e "${RED}Erro: package.json não encontrado em $SOURCE_DIR${NC}"
    echo -e "${YELLOW}Certifique-se de que está apontando para o diretório correto do projeto${NC}"
    exit 1
fi

if [ ! -d "$SOURCE_DIR/backend" ]; then
    echo -e "${RED}Erro: Diretório backend não encontrado em $SOURCE_DIR${NC}"
    exit 1
fi

if [ ! -d "$SOURCE_DIR/src" ]; then
    echo -e "${RED}Erro: Diretório src não encontrado em $SOURCE_DIR${NC}"
    exit 1
fi

echo -e "${BLUE}Origem: $SOURCE_DIR${NC}"
echo -e "${BLUE}Destino: $TARGET_DIR${NC}"
echo

# Criar diretório de destino se não existir
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${BLUE}Criando diretório de destino...${NC}"
    sudo mkdir -p "$TARGET_DIR"
    sudo chown $USER:$USER "$TARGET_DIR"
fi

# Verificar permissões
if [ ! -w "$TARGET_DIR" ]; then
    echo -e "${YELLOW}Ajustando permissões do diretório de destino...${NC}"
    sudo chown $USER:$USER "$TARGET_DIR"
fi

echo -e "${BLUE}Copiando arquivos...${NC}"

# Copiar arquivos principais
echo -e "${BLUE}📁 Copiando estrutura principal...${NC}"
cp -r "$SOURCE_DIR"/* "$TARGET_DIR/" 2>/dev/null || {
    echo -e "${YELLOW}Alguns arquivos podem ter falhado, tentando com sudo...${NC}"
    sudo cp -r "$SOURCE_DIR"/* "$TARGET_DIR/"
    sudo chown -R $USER:$USER "$TARGET_DIR"
}

# Verificar se a cópia foi bem-sucedida
echo -e "${BLUE}Verificando arquivos copiados...${NC}"

REQUIRED_FILES=(
    "package.json"
    "vite.config.ts"
    "tailwind.config.js"
    "backend/package.json"
    "backend/server.js"
    "src/main.tsx"
    "src/App.tsx"
)

REQUIRED_DIRS=(
    "backend"
    "src"
    "scripts"
    "supabase"
)

# Verificar arquivos
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$TARGET_DIR/$file" ]; then
        echo -e "${GREEN}✓ $file${NC}"
    else
        echo -e "${RED}✗ $file${NC}"
    fi
done

# Verificar diretórios
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$TARGET_DIR/$dir" ]; then
        echo -e "${GREEN}✓ $dir/${NC}"
    else
        echo -e "${RED}✗ $dir/${NC}"
    fi
done

# Criar diretórios necessários se não existirem
echo -e "${BLUE}Criando diretórios necessários...${NC}"
mkdir -p "$TARGET_DIR"/{uploads,logs,backups}

# Configurar permissões
echo -e "${BLUE}Configurando permissões...${NC}"
chmod -R 755 "$TARGET_DIR"
chmod +x "$TARGET_DIR"/scripts/*.sh 2>/dev/null || true

# Verificar tamanho
SOURCE_SIZE=$(du -sh "$SOURCE_DIR" | cut -f1)
TARGET_SIZE=$(du -sh "$TARGET_DIR" | cut -f1)

echo
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}  CÓPIA CONCLUÍDA!             ${NC}"
echo -e "${GREEN}================================${NC}"
echo
echo -e "${BLUE}Estatísticas:${NC}"
echo -e "📁 Origem: $SOURCE_SIZE"
echo -e "📁 Destino: $TARGET_SIZE"
echo -e "📍 Localização: $TARGET_DIR"
echo
echo -e "${BLUE}Próximos passos:${NC}"
echo -e "1. cd $TARGET_DIR"
echo -e "2. bash scripts/configurar-codigo.sh"
echo -e "3. bash scripts/start-development.sh"
echo
echo -e "${BLUE}Estrutura criada:${NC}"
ls -la "$TARGET_DIR" | head -10
echo
echo -e "${GREEN}✅ Arquivos prontos para configuração!${NC}"
