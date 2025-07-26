#!/bin/bash

# Script pós-instalação para configurar o DocManage
# Execute após a instalação dos pacotes do sistema

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  DOCMANAGE - PÓS-INSTALAÇÃO   ${NC}"
echo -e "${BLUE}================================${NC}"
echo

# Verificar se estamos no diretório correto
if [ ! -f "package.json" ]; then
    echo -e "${RED}Erro: Execute este script no diretório raiz do projeto DocManage${NC}"
    echo -e "${YELLOW}Exemplo: cd /opt/docmanage && bash scripts/pos-instalacao.sh${NC}"
    exit 1
fi

# Verificar se o diretório backend existe
if [ ! -d "backend" ]; then
    echo -e "${RED}Erro: Diretório backend não encontrado${NC}"
    echo -e "${YELLOW}Certifique-se de que todos os arquivos do projeto estão no diretório atual${NC}"
    exit 1
fi

echo -e "${BLUE}1. Configurando banco de dados...${NC}"

# Verificar se PostgreSQL está rodando
if ! systemctl is-active --quiet postgresql; then
    echo -e "${YELLOW}Iniciando PostgreSQL...${NC}"
    sudo systemctl start postgresql
fi

# Executar schema do banco se existir
if [ -f "backend/scripts/database-schema.sql" ]; then
    echo -e "${BLUE}Executando schema do banco de dados...${NC}"
    sudo -u postgres psql -d docmanage -f backend/scripts/database-schema.sql
    echo -e "${GREEN}✓ Schema do banco executado${NC}"
else
    echo -e "${YELLOW}⚠ Arquivo de schema não encontrado em backend/scripts/database-schema.sql${NC}"
fi

echo -e "${BLUE}2. Instalando dependências do frontend...${NC}"
npm install
echo -e "${GREEN}✓ Dependências do frontend instaladas${NC}"

echo -e "${BLUE}3. Instalando dependências do backend...${NC}"
cd backend
npm install
cd ..
echo -e "${GREEN}✓ Dependências do backend instaladas${NC}"

echo -e "${BLUE}4. Criando diretórios necessários...${NC}"
mkdir -p logs uploads backups
echo -e "${GREEN}✓ Diretórios criados${NC}"

echo -e "${BLUE}5. Configurando permissões...${NC}"
# Dar permissão aos scripts
chmod +x scripts/*.sh 2>/dev/null || true

# Configurar permissões dos diretórios
if [ -w "/opt/docmanage" ]; then
    sudo chown -R $USER:$USER /opt/docmanage 2>/dev/null || true
    chmod -R 755 /opt/docmanage 2>/dev/null || true
fi

echo -e "${GREEN}✓ Permissões configuradas${NC}"

echo -e "${BLUE}6. Verificando configuração...${NC}"

# Verificar se arquivo .env existe no backend
if [ ! -f "backend/.env" ]; then
    echo -e "${YELLOW}⚠ Arquivo backend/.env não encontrado${NC}"
    if [ -f "backend/.env.example" ]; then
        echo -e "${BLUE}Copiando .env.example para .env...${NC}"
        cp backend/.env.example backend/.env
        echo -e "${YELLOW}⚠ IMPORTANTE: Edite backend/.env com suas configurações${NC}"
    fi
fi

# Verificar se arquivo .env existe no frontend
if [ ! -f ".env" ]; then
    echo -e "${BLUE}Criando arquivo .env para o frontend...${NC}"
    cat > .env << 'EOF'
VITE_API_BASE_URL=/api
VITE_API_TIMEOUT=30000
VITE_APP_NAME=DocManage
VITE_APP_VERSION=1.0.0
EOF
    echo -e "${GREEN}✓ Arquivo .env criado${NC}"
fi

echo -e "${BLUE}7. Testando conexões...${NC}"

# Testar PostgreSQL
if sudo -u postgres psql -d docmanage -c "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Conexão com PostgreSQL OK${NC}"
else
    echo -e "${RED}✗ Erro na conexão com PostgreSQL${NC}"
fi

# Testar Redis
if redis-cli ping > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Conexão com Redis OK${NC}"
else
    echo -e "${YELLOW}⚠ Redis não está respondendo${NC}"
fi

echo
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}  CONFIGURAÇÃO CONCLUÍDA!      ${NC}"
echo -e "${GREEN}================================${NC}"
echo
echo -e "${BLUE}Para iniciar o sistema:${NC}"
echo
echo -e "${YELLOW}# Modo desenvolvimento${NC}"
echo -e "bash scripts/start-development.sh"
echo
echo -e "${YELLOW}# Ou manualmente:${NC}"
echo -e "# Terminal 1 - Backend"
echo -e "cd backend && npm run dev"
echo
echo -e "# Terminal 2 - Frontend"
echo -e "npm run dev"
echo
echo -e "${BLUE}URLs de acesso:${NC}"
echo -e "🌐 Frontend: http://localhost:5173"
echo -e "🔧 API: http://localhost:3000"
echo -e "📊 Health: http://localhost:3000/health"
echo
echo -e "${BLUE}Credenciais padrão:${NC}"
echo -e "📧 Email: admin@docmanage.com"
echo -e "🔑 Senha: admin123!"
echo
echo -e "${RED}⚠ IMPORTANTE: Altere a senha padrão após o primeiro login!${NC}"
