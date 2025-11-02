#!/usr/bin/env bash
# =====================================================
# OSCentral.sh — Central de Reinstalação de Sistemas Linux
# =====================================================
# Projeto: OSCentral
# Desenvolvimento: GitXYZ08
# Versão: 1.1
# Função: Ferramenta unificada para reinstalar distribuições Linux
# Suporte: Debian, Ubuntu, Kali, Fedora, CentOS, Arch, Alpine, openSUSE, openEuler e derivados
# =====================================================

set -euo pipefail
IFS=$'\n\t'

WORKDIR="/mnt/oscentral"
LOGFILE="/root/oscentral_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$WORKDIR"
exec > >(tee -a "$LOGFILE") 2>&1

# ---------------------
# Funções utilitárias
# ---------------------
pause() { read -rp "Pressione Enter para continuar..."; }

require_root() {
  [[ $EUID -eq 0 ]] || { echo "❌ Este script precisa ser executado como root"; exit 1; }
}

detect_disk() {
  echo "Discos disponíveis:"
  lsblk -dno NAME,SIZE,MODEL
  read -rp "Escolha o disco para reinstalar (ex: /dev/vda): " DISK
  [[ -b "$DISK" ]] || { echo "Disco inválido"; exit 1; }
}

confirm_danger() {
  echo
  echo "⚠️  ATENÇÃO: isso vai apagar TODO o conteúdo de $DISK!"
  read -rp "Digite YES para continuar: " CONFIRM
  [[ "$CONFIRM" == "YES" ]] || exit 1
}

generate_root_pass() {
  ROOT_PASS=$(openssl rand -base64 14)
  echo "Senha root gerada: $ROOT_PASS"
}

ask_network() {
  echo "Configuração de rede:"
  echo "1) DHCP automático"
  echo "2) IP estático"
  read -rp "Escolha [1/2]: " NETMODE
  if [[ "$NETMODE" == "2" ]]; then
    read -rp "Interface de rede (ex: ens3): " IFACE
    read -rp "IP/CIDR (ex: 192.168.0.100/24): " IPCIDR
    read -rp "Gateway: " GATEWAY
    read -rp "DNS (ex: 1.1.1.1 8.8.8.8): " DNS
  else
    IFACE="" IPCIDR="" GATEWAY="" DNS=""
  fi
}

backup_home_etc() {
  read -rp "Deseja fazer backup de /etc e /home antes? [y/N]: " BACKUP_ANS
  if [[ "$BACKUP_ANS" =~ ^[Yy] ]]; then
    BACKUP_DIR="/root/oscentral_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    echo "Fazendo backup de /etc e /home para $BACKUP_DIR"
    rsync -aAXv --delete /etc "$BACKUP_DIR/etc" || true
    rsync -aAXv /home "$BACKUP_DIR/home" || true
  fi
}

# ---------------------
# Pós-instalação automática
# ---------------------
post_install_config() {
  echo "⚙️ Configurando pós-instalação..."
  chroot "$WORKDIR" /bin/bash -c "echo 'root:$ROOT_PASS' | chpasswd"
  read -rp "Hostname para o sistema instalado: " HOSTNAME
  echo "$HOSTNAME" > "$WORKDIR/etc/hostname"

  # Configurar hosts
  cat > "$WORKDIR/etc/hosts" <<EOF
127.0.0.1   localhost
127.0.1.1   $HOSTNAME
EOF

  # Configuração de rede estática se definida
  if [[ -n "$IFACE" && -n "$IPCIDR" ]]; then
    cat > "$WORKDIR/etc/network/interfaces" <<EOF
auto $IFACE
iface $IFACE inet static
    address $IPCIDR
    gateway $GATEWAY
    dns-nameservers $DNS
EOF
  fi

  # Gerar fstab
  genfstab -U "$WORKDIR" > "$WORKDIR/etc/fstab" || true

  # Instalar GRUB
  if command -v grub-install >/dev/null 2>&1; then
    chroot "$WORKDIR" /bin/bash -c "grub-install $DISK && update-grub || true"
  fi

  echo "✅ Pós-instalação concluída!"
}

# ---------------------
# Funções de instalação
# ---------------------
install_debootstrap() {
  local DIST=$1 MIRROR=$2
  echo "🔧 Instalando $DIST via debootstrap..."
  apt-get update -y
  apt-get install -y debootstrap genfstab grub2-common || true
  debootstrap --arch amd64 "$DIST" "$WORKDIR" "$MIRROR"
  post_install_config
}

install_rhel_like() {
  local RELEASE=$1 REPO=$2
  echo "🔧 Instalando sistema baseado em RHEL ($RELEASE)..."
  dnf install -y dnf
  dnf --releasever="$RELEASE" --installroot="$WORKDIR" --disablerepo='*' --enablerepo="$REPO" groupinstall -y "Minimal Install"
  post_install_config
}

install_arch() {
  echo "🔧 Instalando Arch Linux..."
  pacman -Sy --noconfirm arch-install-scripts || true
  pacstrap "$WORKDIR" base linux linux-firmware
  post_install_config
}

install_suse() {
  local VERSION=$1
  echo "🔧 Instalando openSUSE $VERSION..."
  zypper --root "$WORKDIR" --non-interactive in patterns-base-base
  post_install_config
}

install_alpine() {
  echo "🔧 Instalando Alpine Linux..."
  apk add --root "$WORKDIR" --initdb alpine-base
  post_install_config
}

# ---------------------
# Menus
# ---------------------
main_menu() {
  clear
  echo "================================="
  echo "     OSCentral Reinstaller       "
  echo "   Desenvolvimento: GitXYZ08     "
  echo "================================="
  echo "Escolha a distribuição:"
  echo "1) Debian"
  echo "2) Ubuntu"
  echo "3) Kali Linux"
  echo "4) Arch Linux"
  echo "5) Fedora"
  echo "6) CentOS Stream"
  echo "7) openSUSE"
  echo "8) Alpine Linux"
  echo "9) openEuler / Alma / Anolis"
  echo "0) Sair"
  read -rp "Opção: " CHOICE
  case $CHOICE in
    1) install_debian ;; 2) install_ubuntu ;; 3) install_kali ;; 4) install_arch ;;
    5) install_fedora ;; 6) install_centos ;; 7) install_opensuse ;;
    8) install_alpine ;; 9) install_openeuler ;; 0) exit 0 ;;
    *) echo "Opção inválida";;
  esac
}

# ---------------------
# Instalações específicas
# ---------------------
install_debian() {
  echo "Versões Debian: 11 (bullseye), 12 (bookworm), 13 (trixie)"
  read -rp "Escolha versão: " VER
  detect_disk
  confirm_danger
  ask_network
  backup_home_etc
  install_debootstrap "$VER" "https://deb.debian.org/debian"
}

install_ubuntu() {
  echo "Versões Ubuntu: 20.04 (focal), 22.04 (jammy), 24.04 (noble)"
  read -rp "Escolha versão: " VER
  detect_disk
  confirm_danger
  ask_network
  backup_home_etc
  install_debootstrap "$VER" "http://archive.ubuntu.com/ubuntu"
}

install_kali() {
  detect_disk
  confirm_danger
  ask_network
  backup_home_etc
  install_debootstrap "kali-rolling" "http://http.kali.org/kali"
}

install_fedora() {
  echo "Versões Fedora: 39, 40"
  read -rp "Escolha versão: " VER
  detect_disk
  confirm_danger
  ask_network
  backup_home_etc
  install_rhel_like "$VER" "fedora"
}

install_centos() {
  echo "CentOS Stream versões: 8, 9"
  read -rp "Escolha versão: " VER
  detect_disk
  confirm_danger
  ask_network
  backup_home_etc
  install_rhel_like "$VER" "baseos"
}

install_openeuler() {
  echo "Distribuições compatíveis: openEuler, AlmaLinux, Anolis"
  read -rp "Versão (8/9): " VER
  detect_disk
  confirm_danger
  ask_network
  backup_home_etc
  install_rhel_like "$VER" "baseos"
}

install_opensuse() {
  echo "Versões openSUSE: leap-15.6, tumbleweed"
  read -rp "Escolha versão: " VER
  detect_disk
  confirm_danger
  ask_network
  backup_home_etc
  install_suse "$VER"
}

install_arch() {
  detect_disk
  confirm_danger
  ask_network
  backup_home_etc
  install_arch
}

install_alpine() {
  detect_disk
  confirm_danger
  ask_network
  backup_home_etc
  install_alpine
}

# ---------------------
# Execução principal
# ---------------------
require_root
while true; do
  main_menu
  pause
done
