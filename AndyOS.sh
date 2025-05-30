#!/bin/bash
# AndyOS v1.1.2 - Build: random (Fixed Permission Issues)

# =============================================
# FUNGSI UTAMA YANG DIPERBAIKI
# =============================================
main() {
    # Perbaikan masalah izin
    fix_permissions
    
    # Load config jika ada
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
    
    # Setup pertama kali
    if [ ! -f ~/.andyos_installed ]; then
        install_dependencies
        setup_theme
        setup_desktop
        touch ~/.andyos_installed
    fi
    
    create_terminal_script
    show_main_menu
}

# =============================================
# FUNGSI PERBAIKAN IZIN
# =============================================
fix_permissions() {
    # Beri izin pada file skrip ini
    chmod +x "$0"
    
    # Beri izin pada direktori penting
    mkdir -p "$THEME_DIR" "$DESKTOP_DIR" "$APPS_DIR"
    chmod 755 "$THEME_DIR" "$DESKTOP_DIR" "$APPS_DIR"
    
    # Perbaikan izin Wine
    if [ -d "$WINEPREFIX" ]; then
        chmod 755 -R "$WINEPREFIX"
    fi
}

# =============================================
# FUNGSI INSTALASI WINE (DIPERBAIKI)
# =============================================
install_wine() {
    echo -e "\e[32m[*] Menginstal Wine dengan izin yang benar...\e[0m"
    
    # Perintah yang lebih aman
    pkg update -y
    pkg install -y tur-repo
    pkg install -y wine winetricks -o Dpkg::Options::="--force-overwrite"
    
    # Konfigurasi Wine dengan izin yang tepat
    export WINEDLLOVERRIDES="mscoree,mshtml="
    wine wineboot --init 2>&1 | grep -v "fixme"  # Sembunyikan pesan warning
    winetricks corefonts
    
    # Perbaikan izin
    chmod 755 -R "$WINEPREFIX"
    
    echo -e "\e[32m[✓] Wine terinstal dengan sukses!\e[0m"
    sleep 2
}

# ... (bagian lain skrip tetap sama) ...
