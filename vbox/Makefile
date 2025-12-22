FREEBSD_VERSION := 15.0-RELEASE
FREEBSD_IMAGE   := FreeBSD-$(FREEBSD_VERSION)-amd64-zfs.vhd
CHECKSUM_URL    := https://download.freebsd.org/releases/VM-IMAGES/$(FREEBSD_VERSION)/amd64/Latest/CHECKSUM.SHA256
IMAGE_URL       := https://download.freebsd.org/releases/VM-IMAGES/$(FREEBSD_VERSION)/amd64/Latest/$(FREEBSD_IMAGE).xz
IMAGE_DIR       := ./image
TMP_DIR         := ./tmp
SSH_DIR         := ./.ssh

SHARED_FOLDER := $(shell echo ~/Projects)

NAME=joker

VBoxManage := $(shell sh vbox-manage-path.sh)
VMName     := FreeBSD-joker
MemoryMB   := 4096
DiskSizeGB := 30
CPUCount   := 2

DATA_DISK_SIZE_GB := 30
DATA_DISK_VDI     := $(PWD)/$(IMAGE_DIR)/$(VMName)-data.vdi

ifeq ('$(VBoxManage)',)
  $(error Failed to detect VBoxManage path)
endif

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


$(IMAGE_DIR):
	mkdir -p $(IMAGE_DIR)

# Получаем контрольные суммы образов
$(IMAGE_DIR)/$(FREEBSD_VERSION)/CHECKSUM.SHA256:
	@set -x; \
	set -e; \
	mkdir -p '$(TMP_DIR)'; \
	tmp_file="$(TMP_DIR)/CHECKSUM.SHA256.$$$$"; \
	trap 'rm "$$tmp_file" || true' EXIT; \
	curl '$(CHECKSUM_URL)' -Lo "$$tmp_file"; \
	mkdir -p '$(IMAGE_DIR)/$(FREEBSD_VERSION)'; \
	mv "$$tmp_file" '$(IMAGE_DIR)/$(FREEBSD_VERSION)/CHECKSUM.SHA256'

# Получам образ FreeBSD
$(IMAGE_DIR)/$(FREEBSD_VERSION)/$(FREEBSD_IMAGE): $(IMAGE_DIR)/$(FREEBSD_VERSION)/CHECKSUM.SHA256
	@set -x; \
	set -e; \
	tmp_dir="$(TMP_DIR)/$$$$"; \
	mkdir -p $$tmp_dir; \
	trap 'rm -fr "$$tmp_dir"' EXIT; \
	curl '$(IMAGE_URL)' -Lo "$$tmp_dir/$(FREEBSD_IMAGE).xz"; \
	grep "$$(cd "$$tmp_dir" && sha256sum --tag '$(FREEBSD_IMAGE).xz')" '$(IMAGE_DIR)/$(FREEBSD_VERSION)/CHECKSUM.SHA256'; \
	xz -d "$$tmp_dir/$(FREEBSD_IMAGE).xz"; \
	mv "$$tmp_dir/$(FREEBSD_IMAGE)" '$(IMAGE_DIR)/$(FREEBSD_VERSION)/$(FREEBSD_IMAGE)'


# Создаем эталонную VM (рабочие клоны со снапшота initial)
.create-FreeBSD-$(FREEBSD_VERSION): $(IMAGE_DIR)/$(FREEBSD_VERSION)/$(FREEBSD_IMAGE)
	#'$(VBoxManage)' createvm --name='FreeBSD-$(FREEBSD_VERSION)' --platform-architecture=x86 --ostype FreeBSD_64 --register
	'$(VBoxManage)' createvm  --name='FreeBSD-$(FREEBSD_VERSION)' --ostype FreeBSD_64 --default --register
	'$(VBoxManage)' storagectl    'FreeBSD-$(FREEBSD_VERSION)' --name SATA --add sata --controller IntelAhci
	'$(VBoxManage)' storageattach 'FreeBSD-$(FREEBSD_VERSION)' --storagectl "SATA" --port 0 --device 0 --type hdd --medium '$(IMAGE_DIR)/$(FREEBSD_VERSION)/$(FREEBSD_IMAGE)'
	'$(VBoxManage)' snapshot      'FreeBSD-$(FREEBSD_VERSION)' take initial
	touch '$@'

.PHONY: create-freebsd
create-freebsd: .create-FreeBSD-$(FREEBSD_VERSION) ## Скачать образ и создать эталонную VM FreeBSD $(FREEBSD_VERSION)

.PHONY: delete-freebsd
delete-freebsd: ## Удалить эталонную VM
	'$(VBoxManage)' snapshot      'FreeBSD-$(FREEBSD_VERSION)' delete initial
	'$(VBoxManage)' storageattach 'FreeBSD-$(FREEBSD_VERSION)' --storagectl SATA --port 0 --device 0 --medium none
	'$(VBoxManage)' unregistervm  'FreeBSD-$(FREEBSD_VERSION)' --delete
	rm '.create-FreeBSD-$(FREEBSD_VERSION)'


# Создаем клон для joker
.create-joker: .create-FreeBSD-$(FREEBSD_VERSION)
	'$(VBoxManage)' clonevm 'FreeBSD-$(FREEBSD_VERSION)' --mode=machine --name=$(VMName) --register --options=linked --snapshot=initial
	'$(VBoxManage)' modifyvm '$(VMName)' --memory $(MemoryMB) --cpus '$(CPUCount)'
	'$(VBoxManage)' modifyvm '$(VMName)' --nic1 nat --natpf1 'ssh,tcp,,2222,,22'
	'$(VBoxManage)' modifyvm '$(VMName)' --natpf1 'joker-api,tcp,,2375,,2375'
	'$(VBoxManage)' sharedfolder add '$(VMName)' --name='projects' \
		--hostpath='$(SHARED_FOLDER)' --automount --auto-mount-point=/home/joker/projects
	touch '$@'

.PHONY: create-joker 
create-joker: .create-joker ## Создать рабочую VM (клон от initial-снапшота)

.PHONY: delete-joker
delete-joker: ## Удалить рабочую VM
	-$(MAKE) joker-detach-data-disk
	-'$(VBoxManage)' snapshot '$(VMName)' delete first-boot
	-rm .first-boot
	'$(VBoxManage)' unregistervm '$(VMName)' --delete
	-rm -fr ./.ssh
	rm .create-joker


$(DATA_DISK_VDI):
	'$(VBoxManage)' createmedium disk --filename '$(DATA_DISK_VDI)' --size $$(( $(DATA_DISK_SIZE_GB) * 1024 ))

.PHONY: create-data-disk
create-data-disk: $(DATA_DISK_VDI)

.attach-data-disk: .create-joker $(DATA_DISK_VDI)
	'$(VBoxManage)' storageattach '$(VMName)' --storagectl SATA --port 1 --device 0 --type hdd --medium '$(DATA_DISK_VDI)'
	touch '$@'

.PHONY: attach-data-disk detach-data-disk
attach-data-disk: .attach-data-disk
detach-data-disk:
	'$(VBoxManage)' storageattach '$(VMName)' --storagectl SATA --port 1 --device 0 --type hdd --medium none
	rm .attach-data-disk

.first-boot: .create-joker
	VBoxManage='$(VBoxManage)' VMName='$(VMName)' \
		TMP_DIR='$(TMP_DIR)' SSH_DIR='$(SSH_DIR)' sh first-boot.sh
	'$(VBoxManage)' controlvm '$(VMName)' acpipowerbutton	
	VBoxManage='$(VBoxManage)' VMName='$(VMName)' sh wait-for-poweroff.sh
	'$(VBoxManage)' snapshot '$(VMName)' take first-boot

.init-packages:
	sh joker-run joker.d/pkg-bootstrap
	touch $@

.install-virtualbox-additions: .init-packages
	sh joker-run joker.d/install-virtualbox-additions
	touch $@

.install-sudo: .init-packages
	sh joker-run joker.d/install-sudo
	touch $@

.install-mc: .init-packages
	sh joker-run joker.d/install-mc
	touch $@

.add-mount-point: .install-virtualbox-additions
	sh joker-run joker.d/add-mount-point projects /home/joker/projects
	touch $@

.setup-workpool:
	sh joker-run joker.d/setup-workpool
	touch $@

.PHONY: start-joker
start-joker: .first-boot .attach-data-disk ## Запустить joker
	'$(VBoxManage)' startvm '$(VMName)' --type headless
	# press enter on boot menu to speed up start freebsd
	sleep 3 && '$(VBoxManage)' controlvm '$(VMName)' keyboardputscancode 1c

.PHONY: stop-joker 
stop-joker: ## Выключить joker через ACPI
	'$(VBoxManage)' controlvm '$(VMName)' acpipowerbutton
	VBoxManage='$(VBoxManage)' VMName='$(VMName)' sh wait-for-poweroff.sh
	$(MAKE) detach-data-disk

.PHONY: vbox-help
vbox-help: ## Показать справку VBoxManage
	'$(VBoxManage)' --help


.PHONY: clean
clean: ## Остановить и удалить ВСЕ + временные файлы
	-$(MAKE) stop-joker
	-$(MAKE) delete-joker
	-$(MAKE) delete-freebsd
	-rm -fr ./tmp/
