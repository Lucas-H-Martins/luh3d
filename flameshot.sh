#!/usr/bin/env bash
set -euo pipefail

# Script para instalar alternativa ao Lightshot no Linux
# Como Lightshot é nativo do Windows, usaremos Flameshot que é similar e popular no Linux

echo "=== Instalação de Ferramenta de Screenshot (Flameshot) ==="

# Detectar o ambiente desktop
DESKTOP_ENV=""
if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ] || [ "$GDMSESSION" = "gnome" ]; then
    DESKTOP_ENV="gnome"
elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ] || [ "$DESKTOP_SESSION" = "plasma" ]; then
    DESKTOP_ENV="kde"
else
    DESKTOP_ENV="other"
fi

echo "Ambiente detectado: $DESKTOP_ENV"
echo ""

# Instalar Flameshot
echo "Instalando Flameshot..."
sudo apt update
sudo apt install -y flameshot

# Verificar instalação
if ! command -v flameshot &> /dev/null; then
    echo "Erro: Falha ao instalar Flameshot"
    exit 1
fi

echo "✓ Flameshot instalado com sucesso!"
echo ""

# Configurar atalho de teclado baseado no ambiente
if [ "$DESKTOP_ENV" = "gnome" ]; then
    echo "Configurando atalho para GNOME..."
    
    # Desabilitar o screenshot padrão do GNOME para Print
    gsettings set org.gnome.shell.keybindings screenshot "[]"
    gsettings set org.gnome.shell.keybindings show-screenshot-ui "[]"
    
    # Configurar Flameshot para Print Screen
    # Buscar um slot disponível de custom keybinding
    CUSTOM_KEYBINDINGS=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
    
    if [ "$CUSTOM_KEYBINDINGS" = "@as []" ] || [ "$CUSTOM_KEYBINDINGS" = "[]" ]; then
        # Primeira keybinding customizada
        gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
        BINDING_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
    else
        # Adicionar nova keybinding
        NEW_BINDING="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/flameshot/"
        UPDATED_KEYBINDINGS=$(echo "$CUSTOM_KEYBINDINGS" | sed "s/]/, '$NEW_BINDING']/")
        gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$UPDATED_KEYBINDINGS"
        BINDING_PATH="$NEW_BINDING"
    fi
    
    # Configurar o comando do Flameshot
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$BINDING_PATH" name "Flameshot"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$BINDING_PATH" command "flameshot gui"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$BINDING_PATH" binding "Print"
    
    echo "✓ Atalho Print Screen configurado no GNOME"
    
elif [ "$DESKTOP_ENV" = "kde" ]; then
    echo "Configurando atalho para KDE..."
    
    # No KDE, precisamos editar o arquivo de configuração
    KGLOBALSHORTCUTSRC="$HOME/.config/kglobalshortcutsrc"
    
    # Adicionar configuração do Flameshot
    if ! grep -q "\[flameshot.desktop\]" "$KGLOBALSHORTCUTSRC" 2>/dev/null; then
        cat >> "$KGLOBALSHORTCUTSRC" << 'EOF'

[flameshot.desktop]
Capture=Print,none,Take a screenshot
EOF
    fi
    
    echo "✓ Atalho Print Screen configurado no KDE"
    echo "  Nota: Pode ser necessário reiniciar a sessão para aplicar as mudanças"
    
else
    echo "⚠️  Ambiente desktop não reconhecido automaticamente"
    echo ""
    echo "Configure manualmente o atalho Print Screen para executar:"
    echo "  flameshot gui"
    echo ""
    echo "Nas configurações de teclado do seu sistema."
fi

echo ""
echo "=== Instruções de Uso ==="
echo ""
echo "Comandos disponíveis:"
echo "  flameshot gui          - Abre o modo de captura interativa"
echo "  flameshot full         - Captura tela inteira"
echo "  flameshot screen       - Captura tela específica"
echo ""
echo "Atalho configurado:"
echo "  Print Screen           - Abre Flameshot em modo captura"
echo ""
echo "Recursos do Flameshot:"
echo "  • Captura de tela com seleção de área"
echo "  • Ferramentas de edição (setas, texto, formas)"
echo "  • Upload direto para nuvem (Imgur)"
echo "  • Salvar em arquivo ou copiar para clipboard"
echo ""
echo "✓ Instalação concluída!"