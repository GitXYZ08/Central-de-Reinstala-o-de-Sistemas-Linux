# 🧩 OSCentral — Reinstalador Universal de Distribuições Linux

## 📖 Descrição

**OSCentral** é uma ferramenta desenvolvida por **GitXYZ08** para reinstalar sistemas Linux de forma automatizada e centralizada.

Ele permite escolher entre diversas distribuições (Debian, Ubuntu, Kali, Arch, Fedora, CentOS, Alpine, openSUSE, etc.), formatar o disco selecionado e instalar o sistema do zero — tudo via **linha de comando**, sem precisar de ISO.

---

## ⚙️ Funcionalidades principais

- Menu interativo para escolher **distribuição e versão**
- Detecção automática de discos (`lsblk`)
- Confirmação antes de formatar o disco
- Backup opcional de `/etc` e `/home`
- Configuração de rede (DHCP ou IP estático)
- Pós-instalação automática:
  - Geração de `fstab`
  - Definição de `hostname`
  - Instalação do **GRUB**
  - Criação de senha root aleatória
- Log completo em `/root/oscentral_<data>.log`

---

## 🧱 Estrutura do código

O `oscentral.sh` é escrito inteiramente em **Bash**, dividido em módulos:

| Módulo | Função |
|--------|---------|
| `require_root()` | Garante que o script é executado como root |
| `detect_disk()` | Lista discos e solicita o alvo da instalação |
| `confirm_danger()` | Solicita confirmação antes de formatar |
| `ask_network()` | Configura rede (DHCP ou estática) |
| `backup_home_etc()` | Faz backup opcional de `/etc` e `/home` |
| `install_debootstrap()` | Instala Debian, Ubuntu e Kali via `debootstrap` |
| `install_rhel_like()` | Instala Fedora, CentOS, openEuler e similares via `dnf` |
| `install_arch()` | Instala Arch via `pacstrap` |
| `install_suse()` | Instala openSUSE via `zypper` |
| `install_alpine()` | Instala Alpine via `apk` |
| `post_install_config()` | Executa toda a configuração pós-instalação |
| `main_menu()` | Menu principal de seleção |

---

<a href="https://www.buymeacoffee.com/GitXYZ08" target="_blank">
  <img src="https://cdn.buymeacoffee.com/buttons/v2/default-violet.png" alt="Apoia este projeto" width="200" />
</a>
