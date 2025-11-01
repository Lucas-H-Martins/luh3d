#!/usr/bin/env bash
set -euo pipefail

# --- Variáveis de configuração ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_FILE="asdf-v0.18.0-linux-amd64.tar.gz"  # Nome do arquivo binário do asdf
INSTALL_DIR="$HOME/.asdf"   # diretório final onde ficará o asdf
SHELL_RC="$HOME/.bashrc"     # ou ~/.zshrc se você estiver usando Zsh
PLUGINS=("golang" "rust" "python")
SYS_PKGS=(git curl build-essential libssl-dev zlib1g-dev \
          libbz2-dev libreadline-dev libsqlite3-dev \
          wget llvm libncursesw5-dev xz-utils tk-dev \
          libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev)

# --- Passos ---
echo "Atualizando pacotes de sistema..."
sudo apt update
sudo apt install -y "${SYS_PKGS[@]}"

# Verificar se o binário foi informado
if [[ -z "$BIN_FILE" ]]; then
  echo "ERRO: você precisa preencher a variável BIN_FILE com o nome do arquivo do asdf no mesmo diretório que este script."
  exit 1
fi

BIN_PATH="$SCRIPT_DIR/$BIN_FILE"
if [[ ! -f "$BIN_PATH" ]]; then
  echo "ERRO: arquivo binário '$BIN_FILE' não encontrado em '$SCRIPT_DIR'."
  exit 1
fi

echo "Instalando binário asdf a partir de $BIN_PATH..."
# remover instalação prévia se existir
if [[ -d "$INSTALL_DIR" ]]; then
  echo "Diretório $INSTALL_DIR já existe — removendo para instalar de novo."
  rm -rf "$INSTALL_DIR"
fi
mkdir -p "$INSTALL_DIR/bin"

# Extrair o binário
echo "Extraindo binário..."
tar -xzf "$BIN_PATH" -C "$INSTALL_DIR/bin/"
chmod +x "$INSTALL_DIR/bin/asdf"

echo "Configurando links simbólicos..."
# Criar link simbólico global
if [[ -L /usr/local/bin/asdf ]]; then
  echo "Removendo link simbólico antigo..."
  sudo rm /usr/local/bin/asdf
fi
echo "Criando link simbólico para /usr/local/bin/asdf ..."
sudo ln -s "$INSTALL_DIR/bin/asdf" /usr/local/bin/asdf

echo "Configurando e validando o shell rc ($SHELL_RC)..."

# Remover configurações antigas/inválidas do asdf (para instalação via git clone)
echo "Removendo configurações antigas incompatíveis..."
sed -i '/\.asdf\/asdf\.sh/d; /\.asdf\/completions\/asdf\.bash/d' "$SHELL_RC"

# Adicionar o diretório bin ao PATH se ainda não estiver
if ! grep -q "export PATH=\"\$HOME/.asdf/bin:\$PATH\"" "$SHELL_RC"; then
  echo "" >> "$SHELL_RC"
  echo "# asdf configuration" >> "$SHELL_RC"
  echo "export PATH=\"\$HOME/.asdf/bin:\$PATH\"" >> "$SHELL_RC"
fi

# Adicionar o diretório shims ao PATH (onde ficam os executáveis)
if ! grep -q "export PATH=\"\$HOME/.asdf/shims:\$PATH\"" "$SHELL_RC"; then
  echo "export PATH=\"\$HOME/.asdf/shims:\$PATH\"" >> "$SHELL_RC"
fi

# Carregar o PATH para esta sessão
export PATH="$INSTALL_DIR/bin:$PATH"
export PATH="$INSTALL_DIR/shims:$PATH"

echo "Verificando instalação do asdf..."
asdf --version || { echo "Falhou ao executar 'asdf --version'"; exit 1; }

echo "Instalando plugins: ${PLUGINS[*]}..."
for plugin in "${PLUGINS[@]}"; do
  if asdf plugin list | grep -qx "$plugin"; then
    echo "Plugin $plugin já instalado, pulando."
  else
    echo "Adicionando plugin $plugin..."
    asdf plugin add "$plugin"
  fi
done

echo "Instalando e definindo versões para cada plugin..."
for plugin in "${PLUGINS[@]}"; do
  echo "Instalando latest para $plugin ..."
  asdf install "$plugin" latest
  
  # Obter a versão instalada
  latest_version=$(asdf latest "$plugin")
  echo "Definindo versão $latest_version para $plugin ..."
  asdf set "$plugin" "$latest_version"
  
  # Reshim após instalar cada plugin
  echo "Executando reshim para $plugin ..."
  asdf reshim "$plugin" "$latest_version"
done

echo "Concluído! Feche e reabra seu terminal ou execute: source $SHELL_RC"
