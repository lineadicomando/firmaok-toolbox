-include .env

IMAGE ?= localhost/firmaok-toolbox:latest
TOOLBOX ?= firmaok-toolbox
CONTAINER_BACKEND ?= toolbox
CONTAINER_NAME ?= $(TOOLBOX)
CONTAINERFILE ?= container/Containerfile

.DEFAULT_GOAL := help

.PHONY: help build create enter run install reset setup uninstall

help: ## Mostra i comandi disponibili
	@echo "Comandi disponibili:"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## ' $(firstword $(MAKEFILE_LIST)) | sed -n 's/^\([^:]*\):.*## \(.*\)/\1|\2/p' | while IFS='|' read -r target desc; do \
		printf "  %-17s %s\n" "$$target" "$$desc"; \
	done

build: ## Costruisce l'immagine
	podman build -t "$(IMAGE)" -f "$(CONTAINERFILE)" .

create: ## Crea il container se manca
	bash scripts/container-backend.sh create "$(CONTAINER_BACKEND)" "$(CONTAINER_NAME)" "$(IMAGE)"

enter: ## Entra nel container
	bash scripts/container-backend.sh enter "$(CONTAINER_BACKEND)" "$(CONTAINER_NAME)"

run: ## Avvia FirmaOK da console
	bash scripts/container-backend.sh run "$(CONTAINER_BACKEND)" "$(CONTAINER_NAME)" ~/.local/bin/firmaOK

setup: build install ## Flusso iniziale: build + install

install: create ## Installa e configura firmaOK nel toolbox
	CONTAINER_BACKEND="$(CONTAINER_BACKEND)" bash scripts/init.sh "$(CONTAINER_NAME)"

reset: ## Ferma, rimuove e ricrea il toolbox
	CONTAINER_BACKEND="$(CONTAINER_BACKEND)" bash scripts/reset.sh "$(CONTAINER_NAME)" "$(IMAGE)"

uninstall: ## Disinstalla firmaOK e rimuove container/immagine
	bash scripts/uninstall.sh "$(CONTAINER_NAME)" "$(IMAGE)"
