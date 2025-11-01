.PHONY: install clean help

# Default target
.DEFAULT_GOAL := help

help: ## Mostra esta mensagem de ajuda
	@echo "Comandos disponíveis:"
	@echo "  make install    - Instala o asdf e configura o ambiente"
	@echo "  make clean      - Remove arquivos temporários"
	@echo "  make help       - Mostra esta mensagem"

install: ## Instala o asdf e plugins
	@$(MAKE) asdf
	@$(MAKE) docker

docker:
	@echo "Executando instalação do Docker..."
	@bash docker.sh

asdf:
	@echo "Executando instalação do asdf..."
	@bash asdf.sh