#!/usr/bin/env bash
set -euo pipefail

# Script para configurar memória swap de 32GB de forma permanente no Ubuntu

SWAP_SIZE="32G"
SWAP_FILE="/swapfile"

echo "=== Configuração de Memória SWAP ==="
echo "Tamanho: $SWAP_SIZE"
echo ""

# Verificar se já existe um swapfile
if [ -f "$SWAP_FILE" ]; then
    echo "⚠️  Arquivo swap já existe em $SWAP_FILE"
    echo "Desativando swap atual..."
    sudo swapoff "$SWAP_FILE" 2>/dev/null || true
    echo "Removendo arquivo swap antigo..."
    sudo rm -f "$SWAP_FILE"
fi

# Verificar espaço em disco disponível
echo "Verificando espaço em disco..."
AVAILABLE_SPACE=$(df / | awk 'NR==2 {print $4}')
REQUIRED_SPACE=$((32 * 1024 * 1024)) # 32GB em KB

if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
    echo "❌ ERRO: Espaço em disco insuficiente!"
    echo "   Disponível: $(($AVAILABLE_SPACE / 1024 / 1024))GB"
    echo "   Necessário: 32GB"
    exit 1
fi

echo "✓ Espaço em disco suficiente"
echo ""

# Criar arquivo swap de 32GB
echo "Criando arquivo swap de 32GB (isso pode demorar alguns minutos)..."
sudo fallocate -l "$SWAP_SIZE" "$SWAP_FILE" || sudo dd if=/dev/zero of="$SWAP_FILE" bs=1M count=32768 status=progress

# Definir permissões corretas (somente root pode ler/escrever)
echo "Configurando permissões..."
sudo chmod 600 "$SWAP_FILE"

# Formatar como swap
echo "Formatando arquivo como swap..."
sudo mkswap "$SWAP_FILE"

# Ativar swap
echo "Ativando swap..."
sudo swapon "$SWAP_FILE"

# Verificar se o swap está ativo
echo ""
echo "=== Status do SWAP ==="
sudo swapon --show
free -h

# Tornar permanente adicionando ao /etc/fstab
echo ""
echo "Configurando para ativar automaticamente no boot..."

# Remover entradas antigas do swapfile se existirem
sudo sed -i "\|$SWAP_FILE|d" /etc/fstab

# Adicionar nova entrada
echo "$SWAP_FILE none swap sw 0 0" | sudo tee -a /etc/fstab > /dev/null

echo "✓ Entrada adicionada ao /etc/fstab"

# Configurar swappiness (opcional - controla quando o sistema usa swap)
echo ""
echo "=== Configuração de Swappiness ==="
CURRENT_SWAPPINESS=$(cat /proc/sys/vm/swappiness)
echo "Swappiness atual: $CURRENT_SWAPPINESS"
echo ""
echo "Swappiness controla quando o sistema usa swap:"
echo "  0   = Usa swap apenas em emergência"
echo "  10  = Mínimo uso de swap (recomendado para SSDs)"
echo "  60  = Padrão do Ubuntu"
echo "  100 = Máximo uso de swap"
echo ""

# Definir swappiness para 10 (recomendado para sistemas com bastante RAM)
RECOMMENDED_SWAPPINESS=10
echo "Configurando swappiness para $RECOMMENDED_SWAPPINESS (recomendado)..."
sudo sysctl vm.swappiness=$RECOMMENDED_SWAPPINESS

# Tornar permanente
if grep -q "^vm.swappiness" /etc/sysctl.conf; then
    sudo sed -i "s/^vm.swappiness.*/vm.swappiness=$RECOMMENDED_SWAPPINESS/" /etc/sysctl.conf
else
    echo "vm.swappiness=$RECOMMENDED_SWAPPINESS" | sudo tee -a /etc/sysctl.conf > /dev/null
fi

echo "✓ Swappiness configurado permanentemente"

# Configurar cache_pressure (como o kernel recupera memória cache)
echo ""
echo "Configurando vfs_cache_pressure..."
sudo sysctl vm.vfs_cache_pressure=50

if grep -q "^vm.vfs_cache_pressure" /etc/sysctl.conf; then
    sudo sed -i "s/^vm.vfs_cache_pressure.*/vm.vfs_cache_pressure=50/" /etc/sysctl.conf
else
    echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf > /dev/null
fi

echo "✓ vfs_cache_pressure configurado"

echo ""
echo "=== Configuração Final ==="
echo ""
echo "✓ Swap de 32GB criado e ativado com sucesso!"
echo "✓ Configuração permanente adicionada ao /etc/fstab"
echo "✓ Swappiness configurado para $RECOMMENDED_SWAPPINESS"
echo ""
echo "Resumo:"
free -h
echo ""
echo "Para verificar o swap a qualquer momento, use:"
echo "  free -h"
echo "  sudo swapon --show"
echo ""
echo "Instalação concluída!"