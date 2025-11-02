.PHONY: install clean help screenshot swap

# Default target
.DEFAULT_GOAL := help

help: ## Mostra esta mensagem de ajuda
	@echo "Comandos disponíveis:"
	@echo "  make install     - Instala o asdf e configura o ambiente"
	@echo "  make screenshot  - Instala Flameshot (alternativa ao Lightshot)"
	@echo "  make swap        - Configura memória swap de 32GB"
	@echo "  make clean       - Remove arquivos temporários"
	@echo "  make help        - Mostra esta mensagem"

install: ## Instala o asdf e plugins
	@$(MAKE) asdf
	@$(MAKE) docker

screenshot: ## Instala Flameshot e configura Print Screen
	@echo "Executando instalação do Flameshot..."
	@bash lightshot.sh

docker:
	@echo "Executando instalação do Docker..."
	@bash docker.sh

asdf:
	@echo "Executando instalação do asdf..."
	@bash asdf.sh

swap: ## Configura memória swap de 32GB
	@echo "Configurando memória swap de 32GB..."
	@bash swap.sh