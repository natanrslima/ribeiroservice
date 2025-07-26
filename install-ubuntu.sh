#!/bin/bash

# DocManage - Script de Instalação Automática para Ubuntu
# Execute com: bash install-ubuntu.sh

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Função para log
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Header
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  DOCMANAGE - INSTALAÇÃO AUTO  ${NC}"
echo -e "${BLUE}================================${NC}"
echo

# Verificar se é Ubuntu
if ! grep -q "Ubuntu" /etc/os-release; then
    warn "Este script foi feito para Ubuntu. Continuando mesmo assim..."
fi

# Verificar se é root
if [ "$EUID" -eq 0 ]; then
    error "Não execute este script como root!"
fi

# Atualizar sistema
log "Atualizando sistema..."
sudo apt update && sudo apt upgrade -y

# Instalar dependências básicas
log "Instalando dependências básicas..."
sudo apt install -y curl wget git build-essential python3-pip python3-dev

# Instalar Node.js 18
log "Instalando Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verificar Node.js
NODE_VERSION=$(node --version)
log "Node.js instalado: $NODE_VERSION"

# Instalar PostgreSQL
log "Instalando PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib

# Iniciar PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Configurar PostgreSQL
log "Configurando PostgreSQL..."
read -p "Digite a senha para o usuário postgres: " -s POSTGRES_PASSWORD
echo
sudo -u postgres psql -c "ALTER USER postgres PASSWORD '$POSTGRES_PASSWORD';"
sudo -u postgres createdb docmanage

# Instalar Redis
log "Instalando Redis..."
sudo apt install -y redis-server

# Configurar Redis
sudo sed -i 's/supervised no/supervised systemd/' /etc/redis/redis.conf
sudo systemctl restart redis-server
sudo systemctl enable redis-server

# Instalar Tesseract OCR
log "Instalando Tesseract OCR..."
sudo apt install -y tesseract-ocr tesseract-ocr-por imagemagick

# Instalar Nginx (opcional)
read -p "Instalar Nginx para produção? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Instalando Nginx..."
    sudo apt install -y nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
fi

# Criar diretório do projeto
log "Criando diretório do projeto..."
sudo mkdir -p /opt/docmanage
sudo chown $USER:$USER /opt/docmanage

# Gerar senhas seguras
log "Gerando configurações de segurança..."
JWT_SECRET=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
SESSION_SECRET=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)

# Criar arquivo de configuração do backend
log "Criando configuração do backend..."
mkdir -p /opt/docmanage/backend
cat > /opt/docmanage/backend/.env << EOF
# Server Configuration
NODE_ENV=development
PORT=3000
FRONTEND_URL=http://localhost:5173

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=docmanage
DB_USER=postgres
DB_PASSWORD=$POSTGRES_PASSWORD

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

# JWT Configuration
JWT_SECRET=$JWT_SECRET
JWT_EXPIRES_IN=24h
REFRESH_TOKEN_EXPIRES_IN=7d

# Session Configuration
SESSION_SECRET=$SESSION_SECRET

# File Upload Configuration
UPLOAD_PATH=/opt/docmanage/uploads
MAX_FILE_SIZE=52428800
ALLOWED_FILE_TYPES=pdf,jpg,jpeg,png,docx,xlsx

# OCR Configuration
OCR_ENABLED=true
OCR_LANGUAGE=por
TESSERACT_PATH=/usr/bin/tesseract

# Logging Configuration
LOG_LEVEL=info
LOG_FILE=/opt/docmanage/logs/app.log
EOF

# Criar arquivo de configuração do frontend
log "Criando configuração do frontend..."
cat > /opt/docmanage/.env << EOF
VITE_API_BASE_URL=/api
VITE_API_TIMEOUT=30000
VITE_APP_NAME=DocManage
VITE_APP_VERSION=1.0.0
EOF

# Criar diretórios necessários
mkdir -p /opt/docmanage/{uploads,logs,backups}

# Instalar PM2 globalmente
log "Instalando PM2..."
sudo npm install -g pm2

echo
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}  INSTALAÇÃO CONCLUÍDA!        ${NC}"
echo -e "${GREEN}================================${NC}"
echo
echo -e "${YELLOW}Próximos passos:${NC}"
echo "1. Copie os arquivos do projeto para /opt/docmanage/"
echo "2. Execute o schema do banco de dados"
echo "3. Instale as dependências: cd /opt/docmanage && npm install"
echo "4. Instale as dependências do backend: cd /opt/docmanage/backend && npm install"
echo "5. Inicie o sistema:"
echo "   - Backend: cd /opt/docmanage/backend && npm start"
echo "   - Frontend: cd /opt/docmanage && npm run dev"
echo
echo -e "${BLUE}Configurações salvas em:${NC}"
echo "- Backend: /opt/docmanage/backend/.env"
echo "- Frontend: /opt/docmanage/.env"
echo
echo -e "${BLUE}Credenciais padrão:${NC}"
echo "- Email: admin@docmanage.com"
echo "- Senha: admin123!"
echo
echo -e "${RED}IMPORTANTE: Altere a senha padrão após o primeiro login!${NC}"
