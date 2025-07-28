#!/bin/bash

# Script para verificar se o sistema está pronto para instalação
# Execute: bash verificar-sistema.sh

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  VERIFICAÇÃO DO SISTEMA        ${NC}"
echo -e "${BLUE}================================${NC}"
echo

# Verificar sistema operacional
echo -e "${BLUE}Verificando sistema operacional...${NC}"
if grep -q "Ubuntu" /etc/os-release; then
    VERSION=$(grep VERSION_ID /etc/os-release | cut -d'"' -f2)
    echo -e "${GREEN}✓ Ubuntu $VERSION detectado${NC}"
elif grep -q "Debian" /etc/os-release; then
    VERSION=$(grep VERSION_ID /etc/os-release | cut -d'"' -f2)
    echo -e "${GREEN}✓ Debian $VERSION detectado${NC}"
else
    echo -e "${YELLOW}⚠ Sistema não testado, mas pode funcionar${NC}"
fi

# Verificar se é root
echo -e "${BLUE}Verificando usuário...${NC}"
if [ "$EUID" -eq 0 ]; then
    echo -e "${YELLOW}⚠ Você está executando como root${NC}"
    echo -e "${YELLOW}  Recomendado: usar usuário normal com sudo${NC}"
else
    echo -e "${GREEN}✓ Executando como usuário normal${NC}"
fi

# Verificar sudo
echo -e "${BLUE}Verificando permissões sudo...${NC}"
if sudo -n true 2>/dev/null; then
    echo -e "${GREEN}✓ Permissões sudo OK${NC}"
else
    echo -e "${RED}✗ Sem permissões sudo${NC}"
    echo -e "${YELLOW}  Execute: sudo usermod -aG sudo \$USER${NC}"
    echo -e "${YELLOW}  Depois faça logout e login novamente${NC}"
fi

# Verificar conexão com internet
echo -e "${BLUE}Verificando conexão com internet...${NC}"
if ping -c 1 google.com &> /dev/null; then
    echo -e "${GREEN}✓ Conexão com internet OK${NC}"
else
    echo -e "${RED}✗ Sem conexão com internet${NC}"
fi

# Verificar espaço em disco
echo -e "${BLUE}Verificando espaço em disco...${NC}"
DISK_SPACE=$(df / | awk 'NR==2 {print $4}')
DISK_SPACE_GB=$((DISK_SPACE / 1024 / 1024))
if [ $DISK_SPACE_GB -gt 20 ]; then
    echo -e "${GREEN}✓ Espaço em disco: ${DISK_SPACE_GB}GB disponível${NC}"
else
    echo -e "${YELLOW}⚠ Pouco espaço em disco: ${DISK_SPACE_GB}GB${NC}"
    echo -e "${YELLOW}  Recomendado: pelo menos 20GB${NC}"
fi

# Verificar memória RAM
echo -e "${BLUE}Verificando memória RAM...${NC}"
RAM_MB=$(free -m | awk 'NR==2{print $2}')
RAM_GB=$((RAM_MB / 1024))
if [ $RAM_MB -gt 4000 ]; then
    echo -e "${GREEN}✓ Memória RAM: ${RAM_GB}GB${NC}"
else
    echo -e "${YELLOW}⚠ Pouca memória RAM: ${RAM_GB}GB${NC}"
    echo -e "${YELLOW}  Recomendado: pelo menos 4GB${NC}"
fi

# Verificar portas
echo -e "${BLUE}Verificando portas disponíveis...${NC}"
PORTS=(80 443 3000 5432 6379)
for port in "${PORTS[@]}"; do
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        echo -e "${YELLOW}⚠ Porta $port já está em uso${NC}"
    else
        echo -e "${GREEN}✓ Porta $port disponível${NC}"
    fi
done

# Verificar se curl/wget estão instalados
echo -e "${BLUE}Verificando ferramentas necessárias...${NC}"
if command -v curl &> /dev/null; then
    echo -e "${GREEN}✓ curl instalado${NC}"
else
    echo -e "${YELLOW}⚠ curl não instalado${NC}"
    echo -e "${YELLOW}  Execute: sudo apt install curl${NC}"
fi

if command -v wget &> /dev/null; then
    echo -e "${GREEN}✓ wget instalado${NC}"
else
    echo -e "${YELLOW}⚠ wget não instalado${NC}"
    echo -e "${YELLOW}  Execute: sudo apt install wget${NC}"
fi

echo
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  RESUMO DA VERIFICAÇÃO         ${NC}"
echo -e "${BLUE}================================${NC}"
echo
echo -e "${GREEN}Se todas as verificações estão OK, você pode prosseguir com:${NC}"
echo
echo -e "${YELLOW}# Baixar e executar script de instalação${NC}"
echo -e "wget https://raw.githubusercontent.com/seu-repo/docmanage/main/scripts/install-ubuntu.sh"
echo -e "chmod +x install-ubuntu.sh"
echo -e "sudo ./install-ubuntu.sh"
echo
echo -e "${YELLOW}# Ou executar diretamente${NC}"
echo -e "curl -fsSL https://raw.githubusercontent.com/seu-repo/docmanage/main/scripts/install-ubuntu.sh | sudo bash"
