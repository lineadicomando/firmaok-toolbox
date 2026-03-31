IMAGE ?= localhost/firmaok-toolbox:latest
TOOLBOX ?= firmaok-toolbox
CONTAINERFILE ?= container/Containerfile

.DEFAULT_GOAL := help

.PHONY: help build create enter install reset setup

help: ## Mostra i comandi disponibili
	@echo "Comandi disponibili:"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## ' $(firstword $(MAKEFILE_LIST)) | sed -n 's/^\([^:]*\):.*## \(.*\)/\1|\2/p' | while IFS='|' read -r target desc; do \
		printf "  %-17s %s\n" "$$target" "$$desc"; \
	done

build: ## Costruisce l'immagine
	podman build -t "$(IMAGE)" -f "$(CONTAINERFILE)" .

create: ## Crea il toolbox se manca
	podman container exists "$(TOOLBOX)" || toolbox create -c "$(TOOLBOX)" -i "$(IMAGE)"

enter: ## Entra nel toolbox
	toolbox enter -c "$(TOOLBOX)"

setup: build install ## Flusso iniziale: build + install

install: create ## Installa e configura firmaOK nel toolbox
	bash scripts/init.sh "$(TOOLBOX)"

reset: ## Ferma, rimuove e ricrea il toolbox
	bash scripts/reset.sh "$(TOOLBOX)" "$(IMAGE)"
