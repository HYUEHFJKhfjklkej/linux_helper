#!/usr/bin/env bash
# Настройка QEMU/KVM + libvirt для headless-сервера Ubuntu

set -euo pipefail

TARGET_USER="${SUDO_USER:-$USER}"

echo "==> Обновляем пакеты"
apt-get update -y
apt-get upgrade -y

echo "==> Ставим QEMU/KVM и libvirt-daemon"
apt-get install -y \
  qemu-kvm libvirt-daemon-system libvirt-clients \
  bridge-utils openssh-server

echo "==> Включаем libvirtd"
systemctl enable --now libvirtd.service

echo "==> Добавляем $TARGET_USER в группу libvirt"
adduser "$TARGET_USER" libvirt || true

echo "==> Проверяем/создаём NAT-сеть default"
if ! virsh net-info default &>/dev/null; then
  echo "   - Создаю сеть default"
  virsh net-define /usr/share/libvirt/networks/default.xml
fi
virsh net-autostart default
virsh net-start default || true

echo "==> Проверяем поддержку аппаратной виртуализации"
if command -v kvm-ok &>/dev/null; then
  kvm-ok || true
else
  echo "   - Утилита cpu-checker не установлена (опция). Добавьте при необходимости."
fi

echo "==> Всё готово! Перелогиньтесь и подключайтесь c рабочего ПК:"
echo "    virt-manager  →  qemu+ssh://$TARGET_USER@<IP-или-хост>/system"
