# =============================================================================
#  Odoo multi-version dev environment  (Docker + VS Code + wkhtmltopdf)
#  Bantuan:  make help
# =============================================================================
SHELL := /bin/bash
.DEFAULT_GOAL := help

# ---- Variabel yang bisa di-override:  make up V=18 DB=demo ------------------
V          ?= 17
DB         ?= dev
DEMO       ?= 1
DEBUG      ?= 0
DEBUG_WAIT ?= 0
MODULE     ?=
NAME       ?=

VERSION := $(V).0
DC      := docker compose -p odoo$(V)
RUN     := $(DC) run --rm -e DEBUGPY=0 odoo -c /etc/odoo/odoo.conf

# ---- Port & identitas otomatis per versi (17 -> web 8017, pg 5417, debug 5617)
export ODOO_MAJOR   := $(V)
export ODOO_VERSION := $(VERSION)
export ODOO_PORT    := $(shell echo $$((8000 + $(V))))
export PG_PORT      := $(shell echo $$((5400 + $(V))))
export DEBUG_PORT   := $(shell echo $$((5600 + $(V))))
export HOST_UID     := $(shell id -u)
export HOST_GID     := $(shell id -g)
export DEBUGPY      := $(DEBUG)
export DEBUGPY_WAIT := $(DEBUG_WAIT)

# ---- Base image Ubuntu sesuai versi Python yang didukung Odoo ---------------
ifneq (,$(filter $(V),14 15))
  UBUNTU := 20.04 focal
else ifneq (,$(filter $(V),16 17 18))
  UBUNTU := 22.04 jammy
else
  UBUNTU := 24.04 noble
endif
export UBUNTU_VERSION  := $(word 1,$(UBUNTU))
export UBUNTU_CODENAME := $(word 2,$(UBUNTU))

ifeq ($(DEMO),0)
  DEMO_FLAG := --without-demo=all
endif

require = @test -n "$($(1))" || { echo "Error: isi $(1)=... (contoh: make $@ $(1)=nama)"; exit 1; }

.PHONY: help clone build up down stop restart logs status shell psql odoo-shell \
	    init install update test scaffold dropdb wkhtml clean

help: ## Tampilkan bantuan ini
	@awk 'BEGIN {FS = ":.*##"; printf "\nPemakaian: make \033[36m<target>\033[0m [V=17] [DB=dev] [MODULE=..] [NAME=..] [DEBUG=1]\n\n"} \
	    /^[a-zA-Z_-]+:.*##/ {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""

clone: ## Clone source Odoo versi V (shallow, hanya sekali)
	@mkdir -p src/$(VERSION)/enterprise addons/$(VERSION)
	@if [ -d src/$(VERSION)/odoo/.git ]; then \
	    echo "✔ Source Odoo $(VERSION) sudah ada"; \
	else \
	    git clone --depth 1 --branch $(VERSION) https://github.com/odoo/odoo.git src/$(VERSION)/odoo; \
	fi

build: clone ## Build image Docker versi V
	$(DC) build

up: clone ## Jalankan Odoo versi V (DEBUG=1 untuk debugpy, DEBUG_WAIT=1 untuk menunggu VS Code)
	$(DC) up -d --build
	@echo ""
	@echo "  Odoo $(VERSION)  ->  http://localhost:$(ODOO_PORT)"
	@echo "  PostgreSQL    ->  localhost:$(PG_PORT)  (user/pass: odoo/odoo)"
	@[ "$(DEBUG)" = "1" ] && echo "  debugpy       ->  localhost:$(DEBUG_PORT)" || true
	@echo "  Buat database pertama:  make init V=$(V) DB=$(DB)"
	@echo ""

down: ## Matikan & hapus container versi V (data tetap aman di volume)
	$(DC) down

stop: ## Hentikan container versi V tanpa menghapus
	$(DC) stop

restart: ## Restart Odoo versi V
	$(DC) restart odoo

logs: ## Ikuti log Odoo versi V
	$(DC) logs -f --tail=100 odoo

status: ## Daftar semua container Odoo
	@docker ps -a --filter "name=^odoo[0-9]+-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

shell: ## Masuk bash di container Odoo
	$(DC) exec odoo bash

psql: ## Buka psql ke database DB
	$(DC) exec db psql -U odoo -d $(DB)

odoo-shell: ## Odoo shell (ORM interaktif) pada database DB
	$(DC) exec odoo python /opt/odoo/odoo-bin shell -c /etc/odoo/odoo.conf -d $(DB) --no-http

init: ## Buat database DB + install modul base (DEMO=0 tanpa data demo)
	$(RUN) -d $(DB) -i base $(DEMO_FLAG) --stop-after-init

install: ## Install modul:  make install MODULE=sale
	$(call require,MODULE)
	$(RUN) -d $(DB) -i $(MODULE) --stop-after-init

update: ## Update modul:  make update MODULE=my_module  (atau MODULE=all)
	$(call require,MODULE)
	$(RUN) -d $(DB) -u $(MODULE) --stop-after-init

test: ## Unit test modul di database terpisah:  make test MODULE=my_module
	$(call require,MODULE)
	$(RUN) -d $(DB)_test -i $(MODULE) --test-enable --test-tags /$(MODULE) --stop-after-init --log-level=test

scaffold: ## Buat kerangka modul baru:  make scaffold NAME=my_module
	$(call require,NAME)
	$(DC) run --rm --no-deps --entrypoint python odoo /opt/odoo/odoo-bin scaffold $(NAME) /mnt/extra-addons

dropdb: ## Hapus database DB
	$(DC) exec db dropdb -U odoo --if-exists $(DB)

wkhtml: ## Cek versi wkhtmltopdf di container
	$(DC) exec odoo wkhtmltopdf --version

clean: ## HAPUS container + volume (database & filestore) versi V
	@read -p "Hapus SEMUA data Odoo $(VERSION)? [y/N] " a; \
	if [ "$$a" = "y" ]; then $(DC) down -v --remove-orphans; else echo "Dibatalkan."; fi
