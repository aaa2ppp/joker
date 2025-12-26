NAME := joker

FREEBSD_VERSION := 15.0-RELEASE
FREEBSD_IMAGE   := FreeBSD-$(FREEBSD_VERSION)-amd64-zfs.vhd
CHECKSUM_URL    := https://download.freebsd.org/releases/VM-IMAGES/$(FREEBSD_VERSION)/amd64/Latest/CHECKSUM.SHA256
IMAGE_URL       := https://download.freebsd.org/releases/VM-IMAGES/$(FREEBSD_VERSION)/amd64/Latest/$(FREEBSD_IMAGE).xz
IMAGE_DIR       := ./image/$(FREEBSD_VERSION)
TMP_DIR         := ./tmp

VBoxManage := $(shell sh vbox-manage-path.sh)
ifeq ('$(VBoxManage)',)
  $(error Failed to detect VBoxManage path)
endif

VMName     := FreeBSD-joker
MemoryMB   := 4096
DiskSizeGB := 30
CPUCount   := 2

VBOX_NIC_TYPE := virtio
FBSD_NIC_TYPE := vtnet0

SSH_DIR := .joker/ssh
SSH_KEY := $(SSH_DIR)/id_ed25519

DATA_DISK_SIZE_GB := 30
DATA_DISK_VDI     := $(PWD)/data/$(VMName)-data.vdi

# Convert Git Bash path (like /c/Users/...) to Windows path for VirtualBox
SHARED_FOLDER := $(shell echo ~/Projects | sed -E 's|^/([c-z])/|\1:/|')

all:

# === AUTO-GENERATED HELP ===
# Usage: комментарий вида ## текст после объявления цели
# Пример:
# my-target: ## Описание действия
# 	@echo "done"

.PHONY: help
help: ## Показать эту справку
	@echo "  joker - FreeBSD jail dev platform"
	@echo "======================================="
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / { printf "  %-20s %s\n", $$1, $$2 }' $(MAKEFILE_LIST) 

.PHONY: vbox-help
vbox-help: ## Показать справку VBoxManage
	@'$(VBoxManage)' --help


# === Получение и установка FreeBSD === 

# Получаем контрольные суммы образов
$(IMAGE_DIR)/CHECKSUM.SHA256:
	@set -e; \
	set -x; \
	mkdir -p '$(TMP_DIR)'; \
	tmp_file="$(TMP_DIR)/CHECKSUM.SHA256.$$$$"; \
	trap 'rm "$$tmp_file" || true' EXIT; \
	curl '$(CHECKSUM_URL)' -Lo "$$tmp_file"; \
	mkdir -p '$(IMAGE_DIR)'; \
	mv "$$tmp_file" '$(IMAGE_DIR)/CHECKSUM.SHA256'

# Получам образ FreeBSD
$(IMAGE_DIR)/$(FREEBSD_IMAGE): $(IMAGE_DIR)/CHECKSUM.SHA256
	@set -e; \
	set -x; \
	tmp_dir="$(TMP_DIR)/$$$$"; \
	mkdir -p $$tmp_dir; \
	trap 'rm -fr "$$tmp_dir"' EXIT; \
	curl '$(IMAGE_URL)' -Lo "$$tmp_dir/$(FREEBSD_IMAGE).xz"; \
	grep "$$(cd "$$tmp_dir" && sha256sum --tag '$(FREEBSD_IMAGE).xz')" '$(IMAGE_DIR)/CHECKSUM.SHA256'; \
	xz -d "$$tmp_dir/$(FREEBSD_IMAGE).xz"; \
	mv "$$tmp_dir/$(FREEBSD_IMAGE)" '$(IMAGE_DIR)/$(FREEBSD_IMAGE)'


# Создаем эталонную VM (рабочие клоны со снапшота initial)
.FreeBSD-$(FREEBSD_VERSION): $(IMAGE_DIR)/$(FREEBSD_IMAGE)
	@'$(VBoxManage)' createvm --name='FreeBSD-$(FREEBSD_VERSION)' --ostype FreeBSD_64 --default --register
	@'$(VBoxManage)' storagectl      'FreeBSD-$(FREEBSD_VERSION)' --name SATA --add sata --controller IntelAhci
	@'$(VBoxManage)' storageattach   'FreeBSD-$(FREEBSD_VERSION)' --storagectl "SATA" --port 0 --device 0 --type hdd --medium '$(IMAGE_DIR)/$(FREEBSD_IMAGE)'
	@'$(VBoxManage)' snapshot        'FreeBSD-$(FREEBSD_VERSION)' take initial
	@touch '$@'

.PHONY: create-freebsd
create-freebsd: .FreeBSD-$(FREEBSD_VERSION) ## Скачать образ и создать эталонную VM FreeBSD

.PHONY: delete-freebsd
delete-freebsd: ## Удалить эталонную VM
	@if [ -f ".FreeBSD-$(FREEBSD_VERSION)" ]; then \
		set -e; \
 		'$(VBoxManage)' snapshot      'FreeBSD-$(FREEBSD_VERSION)' restore initial; \
 		'$(VBoxManage)' snapshot      'FreeBSD-$(FREEBSD_VERSION)' delete initial; \
		'$(VBoxManage)' storageattach 'FreeBSD-$(FREEBSD_VERSION)' --storagectl SATA --port 0 --device 0 --medium none; \
		'$(VBoxManage)' unregistervm  'FreeBSD-$(FREEBSD_VERSION)' --delete; \
		rm '.FreeBSD-$(FREEBSD_VERSION)'; \
	fi


# === Создание JOKER ===

# Создаем клон для joker
.joker/create-vm: .FreeBSD-$(FREEBSD_VERSION)
	@mkdir -p "$$(dirname '$@')"
	@'$(VBoxManage)' clonevm  'FreeBSD-$(FREEBSD_VERSION)' --mode=machine --name=$(VMName) --register --options=link --snapshot=initial
	@touch .joker/first-boot
	@touch '$@'

.joker/configure-vm: .joker/create-vm
	@# Use --nictype1 (legacy syntax VBox 6.1 vs --nic-type1) for maximum compatibility: works in VBox 6.1 and still supported in 7.x
	@'$(VBoxManage)' modifyvm '$(VMName)' \
		--graphicscontroller vboxsvga --vram 2 \
		--memory $(MemoryMB) --cpus '$(CPUCount)' \
		--nictype1 $(VBOX_NIC_TYPE) \
		--nic1 nat \
		--natpf1 'ssh,tcp,,2222,,22'
	@touch '$@'

.joker/attach-data-disk: .joker/create-vm
	@[ -f '$(DATA_DISK_VDI)' ] || \
		'$(VBoxManage)' createmedium disk --filename '$(DATA_DISK_VDI)' --size $$(( $(DATA_DISK_SIZE_GB) * 1024 ))
	@'$(VBoxManage)' storageattach '$(VMName)' --storagectl SATA --port 1 --device 0 --type hdd --medium '$(DATA_DISK_VDI)'
	@touch '$@'

.joker/add-shared-folder: .joker/create-vm
	@'$(VBoxManage)' sharedfolder add '$(VMName)' \
		--name='projects' \
		--hostpath='$(SHARED_FOLDER)' \
		--automount --auto-mount-point=/home/joker/projects
	@touch '$@'

.PHONY: detach-data-disk
detach-data-disk:
	@if [ -f .joker/attach-data-disk ]; then \
		set -e; \
		'$(VBoxManage)' storageattach '$(VMName)' --storagectl SATA --port 1 --device 0 --type hdd --medium none; \
		rm .joker/attach-data-disk ; \
	fi

.joker/create: .joker/create-vm .joker/configure-vm .joker/attach-data-disk .joker/add-shared-folder
	@touch '$@'

.PHONY: create-joker 
create-joker: .joker/create ## Создать рабочую VM (клон от эталонной VM)

.PHONY: delete-joker
delete-joker: ## Удалить рабочую VM
	@if [ -f .joker/create-vm ]; then \
		set -e; \
		$(MAKE) stop-joker; \
		$(MAKE) detach-data-disk; \
		'$(VBoxManage)' unregistervm '$(VMName)' --delete; \
		rm -fr .joker/; \
	fi


# === Start/Stop JOKER ===

$(SSH_KEY):
	@mkdir -p '$(SSH_DIR)' && chmod 0700 '$(SSH_DIR)'
	@echo y | ssh-keygen -t ed25519 -f '$@' -N ""

.joker/running: .joker/create $(SSH_KEY)
	@'$(VBoxManage)' startvm '$(VMName)' --type headless
	@sleep 3 && '$(VBoxManage)' controlvm '$(VMName)' keyboardputscancode 1c
	@if [ -f .joker/first-boot ]; then \
		set -e; \
		VBoxManage='$(VBoxManage)' VMName='$(VMName)' sh first-boot.sh; \
		sh wait-for-sshd.sh >$(SSH_DIR)/known_hosts; \
		rm .joker/first-boot; \
	else \
		OFFSET=30 sh wait-for-sshd.sh >/dev/null; \
	fi
	@touch '$@'

.PHONY: start-joker
start-joker: .joker/running ## Запустить joker

.PHONY: stop-joker 
stop-joker: ## Остановить joker через ACPI
	@if [ -f .joker/running ]; then \
		set -e; \
		'$(VBoxManage)' controlvm '$(VMName)' acpipowerbutton; \
		VBoxManage='$(VBoxManage)' VMName='$(VMName)' sh wait-for-poweroff.sh; \
		rm .joker/running; \
	fi

.PHONY: clean
clean: ## Остановить и удалить ВСЕ
	@$(MAKE) stop-joker
	@$(MAKE) delete-joker
	@$(MAKE) delete-freebsd
	@-rm -fr ./tmp/


.joker/init-jail-env: \
	.joker/setup-workpool \
	.joker/mount-shared-folder \
	.joker/configure-iface-modules \
	.joker/configure-bridge0 \
	.joker/install-sudo \
	.joker/install-iocage

	@touch '$@'

init-jail-env: .joker/init-jail-env

.joker/init-packages:
	@$(MAKE) start-joker
	@sh joker-run joker.d/pkg-bootstrap
	@touch '$@'

.joker/install-sudo: .joker/init-packages
	@$(MAKE) start-joker
	@sh joker-run joker.d/install-sudo
	@touch '$@'

.joker/install-mc: .joker/init-packages
	@$(MAKE) start-joker
	@sh joker-run joker.d/install-mc
	@touch '$@'

.joker/setup-workpool:
	@$(MAKE) start-joker
	@DISK=ada1 sh joker-run joker.d/setup-workpool
	@touch '$@'

.joker/mount-shared-folder: .joker/install-virtualbox-additions
	@$(MAKE) start-joker
	@sh joker-run joker.d/mount-shared-folder projects /home/joker/projects
	@touch '$@'

.joker/install-virtualbox-additions: .joker/init-packages
	@$(MAKE) start-joker
	@sh joker-run joker.d/install-virtualbox-additions
	@touch '$@'

.joker/configure-iface-modules:
	@$(MAKE) start-joker
	@FBSD_NIC_TYPE=$(FBSD_NIC_TYPE) sh joker-run joker.d/configure-iface-modules
	@touch '$@'

.joker/configure-bridge0: .joker/configure-iface-modules
	@$(MAKE) start-joker
	@FBSD_NIC_TYPE=$(FBSD_NIC_TYPE) sh joker-run joker.d/configure-bridge0
	@touch '$@'

.joker/install-iocage: .joker/setup-workpool
	@$(MAKE) start-joker
	@sh joker-run joker.d/install-iocage
	@touch '$@'

.joker/create-go-dev-template: .joker/init-jail-env
	@$(MAKE) start-joker
	@sh joker-run joker.d/create-go-dev-template
	@touch '$@'
