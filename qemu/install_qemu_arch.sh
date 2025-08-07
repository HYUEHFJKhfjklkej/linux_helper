#!/usr/bin/env bash
# Настройка QEMU/KVM + libvirt + virt-manager на Arch Linux

set -euo pipefail

### 0. Кто будет администрировать ВМ
TARGET_USER="${SUDO_USER:-$USER}"

echo "==> Обновляем пакеты"
pacman -Sy --noconfirm
pacman -Sy dmidecode

echo "==> Ставим QEMU/KVM и утилиты"
pacman -S --needed --noconfirm \
  qemu-full virt-manager virt-viewer \
  libvirt dnsmasq vde2 bridge-utils \
  openbsd-netcat edk2-ovmf

echo "==> Включаем и запускаем libvirtd"
systemctl enable --now libvirtd.service

echo "==> Добавляем $TARGET_USER в группы kvm и libvirt"
usermod -aG kvm,libvirt "$TARGET_USER"

echo "==> Проверяем/создаём NAT-сеть default"
if ! virsh net-info default &>/dev/null; then
  echo "   - Cоздаю сеть default"
  virsh net-define /usr/share/libvirt/networks/default.xml
fi
virsh net-autostart default
virsh net-start default || true

echo "==> Готово. Перелогиньтесь, чтобы группы вступили в силу."
