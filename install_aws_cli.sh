#!/usr/bin/env bash
set -euo pipefail

# install_aws_cli.sh
# Script para instalar o AWS CLI v2 no Linux (x86_64 ou aarch64) de forma automática.

AWS_ZIP=""
ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64) AWS_ZIP="awscli-exe-linux-x86_64.zip" ;;
  aarch64|arm64) AWS_ZIP="awscli-exe-linux-aarch64.zip" ;;
  *) echo "Arquitetura não suportada: $ARCH" >&2; exit 1 ;;
esac

URL="https://awscli.amazonaws.com/$AWS_ZIP"
TMPDIR=$(mktemp -d)

echo "Instalando dependências necessárias..."
# Detectar gerenciador de pacotes (apt, dnf, yum)
if command -v apt >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y unzip curl || true
elif command -v dnf >/dev/null 2>&1; then
  sudo dnf install -y unzip curl || true
elif command -v yum >/dev/null 2>&1; then
  sudo yum install -y unzip curl || true
else
  echo "Aviso: não foi detectado um gerenciador de pacotes conhecido (apt/dnf/yum). Certifique-se de ter 'unzip' e 'curl' instalados." >&2
fi

echo "Baixando AWS CLI: $URL"
curl -fsSL "$URL" -o "$TMPDIR/$AWS_ZIP"

echo "Extraindo..."
unzip -q "$TMPDIR/$AWS_ZIP" -d "$TMPDIR"

echo "Executando instalador do AWS CLI (pode pedir senha sudo)..."
# --update tenta atualizar uma instalação existente
sudo "$TMPDIR"/aws/install --update || {
  echo "Falha ao executar o instalador do AWS CLI" >&2
  ls -la "$TMPDIR"
  exit 1
}

# Verificar instalação
if command -v aws >/dev/null 2>&1; then
  echo "Instalação concluída: $(aws --version 2>&1)"
else
  echo "Falha: o comando 'aws' não foi encontrado após a instalação" >&2
  exit 1
fi

# Limpeza
echo "Limpando arquivos temporários..."
sudo rm -rf "$TMPDIR"

echo "AWS CLI instalado com sucesso. Para confirmar, rode: aws --version"
