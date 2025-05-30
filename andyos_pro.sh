#!/bin/bash

# Konfigurasi Sistem
ANDYOS_DIR="$HOME/.andyos"
VNC_DISPLAY=":1"
VNC_PASSWD="andyos"
THEME_URL="https://github.com/B00merang-Project/Windows-Longhorn/archive/refs/heads/master.zip"
WINE_VERSIONS=("wine-stable" "wine-devel" "wine-staging-9.5" "wine-ge-custom-8.25" "wine-32bit")
APPS_LIST=("Firefox" "Chromium" "Minetest (Minecraft Clone)" "re3 (GTA 3 Clone)" "VLC Media Player" "Adobe Reader XI" "Media Player Classic" "Wine Task Manager")
OPTIMIZED_CONFIG=1
DXVK_ENABLED=0
RAM_BOOST=1

# Fungsi Optimasi Sistem
optimize_system() {
    # Boost RAM dengan zRAM
    if [ $RAM_BOOST -eq 1 ]; then
        swapoff /dev/zram0 >/dev/null 2>&1
        echo lz4 > /sys/block/zram0/comp_algorithm
        echo 3G > /sys/block/zram0/disksize
        mkswap /dev/zram0 >/dev/null
        swapon /dev/zram0 -p 100 >/dev/null
    fi

    # Optimasi kernel
    sysctl -w vm.swappiness=10 >/dev/null
    sysctl -w vm.vfs_cache_pressure=50 >/dev/null
    sysctl -w vm.dirty_ratio=3 >/dev/null
    sysctl -w vm.dirty_background_ratio=1 >/dev/null
    sysctl -w vm.oom_kill_allocating_task=1 >/dev/null
    
    # Optimasi Wine
    export WINEDEBUG=-all
    export PULSE_LATENCY_MSEC=60
    export STAGING_RT_PRIORITY_SERVER=90
    export WINE_DISABLE_WRITE_WATCH=1
    export WINEESYNC=1
}

# Fungsi Utama
init_andyos() {
    [ ! -d "$ANDYOS_DIR" ] && mkdir -p "$ANDYOS_DIR"
    [ ! -f "$ANDYOS_DIR/config" ] && echo -e "RESOLUTION=1280x720\nWINE_VERSION=wine-ge-custom-8.25\nARCH=win64\nDXVK=1" > "$ANDYOS_DIR/config"
    [ ! -d "$ANDYOS_DIR/theme" ] && install_theme
    [ ! -d "$ANDYOS_DIR/cache" ] && mkdir -p "$ANDYOS_DIR/cache"
    [ ! -d "$ANDYOS_DIR/apps" ] && mkdir -p "$ANDYOS_DIR/apps"
    
    # Load config
    source "$ANDYOS_DIR/config"
    DXVK_ENABLED=$DXVK
    
    # Optimize on start
    optimize_system
}

install_theme() {
    echo "Menginstal tema Windows Longhorn..."
    wget -O "$ANDYOS_DIR/longhorn.zip" "$THEME_URL"
    unzip -q "$ANDYOS_DIR/longhorn.zip" -d "$ANDYOS_DIR/theme"
    rm "$ANDYOS_DIR/longhorn.zip"
    
    # Apply theme
    mkdir -p ~/.themes ~/.icons
    cp -r "$ANDYOS_DIR/theme/Windows-Longhorn-master/Windows Longhorn" ~/.themes/
    cp -r "$ANDYOS_DIR/theme/Windows-Longhorn-master/Windows Longhorn Icons" ~/.icons/
    
    # Create xfce config
    cat > ~/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Windows Longhorn"/>
    <property name="IconThemeName" type="string" value="Windows Longhorn Icons"/>
    <property name="DoubleClickTime" type="int" value="250"/>
    <property name="DoubleClickDistance" type="int" value="5"/>
  </property>
</channel>
EOF
}

start_vnc() {
    echo "Memulai desktop VNC..."
    vncserver -kill "$VNC_DISPLAY" >/dev/null 2>&1
    
    # Create xstartup with optimizations
    cat > ~/.vnc/xstartup <<EOF
#!/bin/bash
xrdb $HOME/.Xresources
startxfce4 &
export WINEPREFIX="$ANDYOS_DIR/wine"
export WINEDLLOVERRIDES="mscoree,mshtml="
export DXVK_LOG_LEVEL=none
export DXVK_STATE_CACHE=1
export DXVK_HUD=0
export MESA_GL_VERSION_OVERRIDE=4.5
export __GL_THREADED_OPTIMIZATIONS=1
export PULSE_LATENCY_MSEC=30
EOF
    
    # Enable DXVK if selected
    if [ $DXVK_ENABLED -eq 1 ]; then
        echo "export DXVK_ASYNC=1" >> ~/.vnc/xstartup
        echo "export WINEDLLOVERRIDES=\"d3d11,d3d10,d3d10core,d3d9,dxgi=n;mscoree,mshtml=\"" >> ~/.vnc/xstartup
    fi
    
    echo "exec startxfce4" >> ~/.vnc/xstartup
    chmod +x ~/.vnc/xstartup
    
    # Start server
    vncserver "$VNC_DISPLAY" -geometry "$RESOLUTION" -depth 24 -name "AndyOS" -localhost -SecurityTypes None
    
    echo -e "\e[1;32mDesktop siap! Gunakan VNC Viewer:\e[0m"
    echo "Alamat: localhost:1"
    echo "Password: $VNC_PASSWD"
    echo ""
    read -p "Tekan Enter untuk kembali ke menu..."
}

install_wine() {
    clear
    echo -e "\e[1;32m"
    echo "  [ Install Wine ]  "
    echo -e "\e[0m"
    PS3="Pilih versi Wine: "
    select wine_ver in "${WINE_VERSIONS[@]}" "Kembali"; do
        if [ "$wine_ver" == "Kembali" ]; then
            break
        elif [[ " ${WINE_VERSIONS[@]} " =~ " ${wine_ver} " ]]; then
            echo "Menginstal $wine_ver..."
            
            # Custom installation for optimized versions
            case $wine_ver in
                wine-ge-custom-8.25)
                    wget -O $ANDYOS_DIR/cache/wine-ge-8.25.tar.xz "https://github.com/GloriousEggroll/wine-ge-custom/releases/download/GE-Proton8-25/wine-lutris-ge-8.25-x86_64.tar.xz"
                    tar -xf $ANDYOS_DIR/cache/wine-ge-8.25.tar.xz -C $PREFIX/opt
                    ln -sf $PREFIX/opt/lutris-ge-8.25-x86_64/bin/wine $PREFIX/bin/wine
                    ln -sf $PREFIX/opt/lutris-ge-8.25-x86_64/bin/wineserver $PREFIX/bin/wineserver
                    ;;
                wine-staging-9.5)
                    pkg install -y wine-staging
                    ;;
                *)
                    pkg install -y "$wine_ver"
                    ;;
            esac
            
            sed -i "s/WINE_VERSION=.*/WINE_VERSION=$wine_ver/" "$ANDYOS_DIR/config"
            echo "Wine $wine_ver berhasil diinstal!"
            sleep 2
            break
        else
            echo "Pilihan tidak valid."
        fi
    done
}

install_app() {
    clear
    echo -e "\e[1;32m"
    echo "  [ Install Aplikasi & Game ]  "
    echo -e "\e[0m"
    PS3="Pilih aplikasi: "
    select app in "${APPS_LIST[@]}" "Kembali"; do
        if [ "$app" == "Kembali" ]; then
            break
        fi
        
        case $app in
            Firefox)
                echo "Menginstal Firefox..."
                wget -O $ANDYOS_DIR/apps/firefox_setup.exe "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US"
                WINEPREFIX="$ANDYOS_DIR/wine" wine $ANDYOS_DIR/apps/firefox_setup.exe
                ;;
            Chromium)
                echo "Menginstal Chromium..."
                wget -O $ANDYOS_DIR/apps/chrome_installer.exe "https://download-chromium.appspot.com/dl/Win?type=exe"
                WINEPREFIX="$ANDYOS_DIR/wine" wine $ANDYOS_DIR/apps/chrome_installer.exe
                ;;
            "Minetest (Minecraft Clone)")
                echo "Menginstal Minetest..."
                pkg install -y minetest
                ;;
            "re3 (GTA 3 Clone)")
                echo "Menginstal re3..."
                git clone https://github.com/GTAmodding/re3.git $ANDYOS_DIR/apps/re3
                cd $ANDYOS_DIR/apps/re3
                ./premake5Linux --with-librw --verbose gmake2
                make -C build config=release_linux-amd64-librw_gl3_glfw-oal
                ;;
            "VLC Media Player")
                echo "Menginstal VLC..."
                wget -O $ANDYOS_DIR/apps/vlc_setup.exe "https://get.videolan.org/vlc/3.0.20/win64/vlc-3.0.20-win64.exe"
                WINEPREFIX="$ANDYOS_DIR/wine" wine $ANDYOS_DIR/apps/vlc_setup.exe
                ;;
            "Adobe Reader XI")
                echo "Menginstal Adobe Reader XI..."
                wget -O $ANDYOS_DIR/apps/adobe_reader.exe "https://ardownload2.adobe.com/pub/adobe/reader/win/11.x/11.0.00/en_US/AdbeRdr11000_en_US.exe"
                WINEPREFIX="$ANDYOS_DIR/wine" wine $ANDYOS_DIR/apps/adobe_reader.exe
                ;;
            "Media Player Classic")
                echo "Menginstal MPC-HC..."
                wget -O $ANDYOS_DIR/apps/mpc_hc_setup.exe "https://github.com/clsid2/mpc-hc/releases/download/2.1.0/MPC-HC.2.1.0.x64.exe"
                WINEPREFIX="$ANDYOS_DIR/wine" wine $ANDYOS_DIR/apps/mpc_hc_setup.exe
                ;;
            "Wine Task Manager")
                echo "Membuat shortcut Task Manager..."
                cat > ~/Desktop/Wine\ Task\ Manager.desktop <<EOF
[Desktop Entry]
Name=Wine Task Manager
Exec=wine taskmgr
Type=Application
Icon=utilities-system-monitor
EOF
                chmod +x ~/Desktop/Wine\ Task\ Manager.desktop
                ;;
        esac
        read -p "Instalasi selesai! Tekan Enter..."
        break
    done
}

system_tweaks() {
    while true; do
        clear
        echo -e "\e[1;32m"
        echo "  [ System Tweaks ]  "
        echo -e "\e[0m"
        echo "1. $( [ $OPTIMIZED_CONFIG -eq 1 ] && echo "✓" || echo " " ) Optimasi Game Berat"
        echo "2. $( [ $DXVK_ENABLED -eq 1 ] && echo "✓" || echo " " ) Aktifkan DXVK (DirectX to Vulkan)"
        echo "3. $( [ $RAM_BOOST -eq 1 ] && echo "✓" || echo " " ) Aktifkan RAM Boost (zRAM)"
        echo "4. Pasang Driver GPU (Termux-X11)"
        echo "5. Kembali"
        
        read -p "Pilih: " opt
        case $opt in
            1) 
                OPTIMIZED_CONFIG=$((1 - OPTIMIZED_CONFIG))
                sed -i "s/OPTIMIZED_CONFIG=.*/OPTIMIZED_CONFIG=$OPTIMIZED_CONFIG/" $0
                echo "Optimasi $( [ $OPTIMIZED_CONFIG -eq 1 ] && echo "diaktifkan" || echo "dimatikan" )!"
                sleep 1
                ;;
            2) 
                DXVK_ENABLED=$((1 - DXVK_ENABLED))
                sed -i "s/DXVK=.*/DXVK=$DXVK_ENABLED/" "$ANDYOS_DIR/config"
                echo "DXVK $( [ $DXVK_ENABLED -eq 1 ] && echo "diaktifkan" || echo "dimatikan" )!"
                sleep 1
                ;;
            3)
                RAM_BOOST=$((1 - RAM_BOOST))
                sed -i "s/RAM_BOOST=.*/RAM_BOOST=$RAM_BOOST/" $0
                echo "RAM Boost $( [ $RAM_BOOST -eq 1 ] && echo "diaktifkan" || echo "dimatikan" )!"
                sleep 1
                ;;
            4)
                echo "Menginstal driver GPU..."
                pkg install -y virglrenderer-android mesa zink
                echo "export GALLIUM_DRIVER=zink" >> ~/.bashrc
                echo "export MESA_VK_WSI_PRESENT_MODE=mailbox" >> ~/.bashrc
                echo "Driver GPU berhasil diinstal!"
                sleep 2
                ;;
            5) break ;;
        esac
    done
}

game_optimizer() {
    clear
    echo -e "\e[1;32m"
    echo "  [ Game Optimizer ]  "
    echo -e "\e[0m"
    
    read -p "Masukkan path game (.exe): " game_path
    if [ ! -f "$game_path" ]; then
        echo "File tidak ditemukan!"
        read -p "Tekan Enter untuk kembali..."
        return
    fi
    
    echo "Mengoptimalkan game..."
    
    # Create custom launcher
    game_name=$(basename "$game_path" .exe)
    cat > ~/Desktop/"$game_name Optimized.desktop" <<EOF
[Desktop Entry]
Name=$game_name (Optimized)
Exec=env __GL_THREADED_OPTIMIZATIONS=1 \\
     MESA_GL_VERSION_OVERRIDE=4.5 \\
     PULSE_LATENCY_MSEC=30 \\
     DXVK_ASYNC=1 \\
     wine "$game_path"
Type=Application
Icon=wine
EOF

    chmod +x ~/Desktop/"$game_name Optimized.desktop"
    
    echo -e "\e[1;32mOptimasi selesai! Shortcut baru telah dibuat di desktop.\e[0m"
    echo "Konfigurasi yang diterapkan:"
    echo "- Multi-threaded GL optimizations"
    echo "- Vulkan async shader compilation"
    echo "- Low audio latency"
    echo "- GL version override"
    read -p "Tekan Enter untuk kembali ke menu..."
}

show_menu() {
    while true; do
        clear
        echo -e "\e[1;32m"
        echo "   █████╗ ███╗   ██╗██████╗ ██╗   ██╗ ██████╗ ███████╗"
        echo "  ██╔══██╗████╗  ██║██╔══██╗╚██╗ ██╔╝██╔═══██╗██╔════╝"
        echo "  ███████║██╔██╗ ██║██║  ██║ ╚████╔╝ ██║   ██║███████╗"
        echo "  ██╔══██║██║╚██╗██║██║  ██║  ╚██╔╝  ██║   ██║╚════██║"
        echo "  ██║  ██║██║ ╚████║██████╔╝   ██║   ╚██████╔╝███████║"
        echo "  ╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝    ╚═╝    ╚═════╝ ╚══════╝"
        echo -e "\e[0m"
        echo "  Play unsupportable PC games, on ANDROID!! (not ios btw)"
        echo -e "\e[1;32m"
        echo "  [ SYSTEM STATUS ]"
        echo -e "\e[0m"
        echo "  Wine: $(grep 'WINE_VERSION' $ANDYOS_DIR/config | cut -d= -f2)"
        echo "  DXVK: $( [ $DXVK_ENABLED -eq 1 ] && echo "Enabled" || echo "Disabled" )"
        echo "  Optimizations: $( [ $OPTIMIZED_CONFIG -eq 1 ] && echo "Active" || echo "Inactive" )"
        echo "  RAM Boost: $( [ $RAM_BOOST -eq 1 ] && echo "Active" || echo "Inactive" )"
        echo ""
        echo "  1. Start AndyOS Desktop"
        echo "  2. Settings"
        echo "  3. Install Wine"
        echo "  4. Install Apps/Games"
        echo "  5. System Tweaks"
        echo "  6. Game Optimizer"
        echo "  7. Exit"
        read -p "Pilih: " choice
        
        case $choice in
            1) start_vnc ;;
            2) settings_menu ;;
            3) install_wine ;;
            4) install_app ;;
            5) system_tweaks ;;
            6) game_optimizer ;;
            7) echo "Sampai jumpa!"; exit 0 ;;
        esac
    done
}

settings_menu() {
    source "$ANDYOS_DIR/config"
    while true; do
        clear
        echo -e "\e[1;32m"
        echo "  [ Settings ]  "
        echo -e "\e[0m"
        echo "1. Resolusi: $RESOLUTION"
        echo "2. Wine: $WINE_VERSION"
        echo "3. Arsitektur: $ARCH"
        echo "4. Kembali"
        read -p "Pilih: " opt
        case $opt in
            1) read -p "Resolusi (contoh: 1920x1080): " res && sed -i "s/RESOLUTION=.*/RESOLUTION=$res/" "$ANDYOS_DIR/config" ;;
            2) 
                PS3="Pilih versi Wine: "
                select wine_ver in "${WINE_VERSIONS[@]}"; do
                    if [[ " ${WINE_VERSIONS[@]} " =~ " ${wine_ver} " ]]; then
                        sed -i "s/WINE_VERSION=.*/WINE_VERSION=$wine_ver/" "$ANDYOS_DIR/config"
                        break
                    else
                        echo "Pilihan tidak valid."
                    fi
                done
                ;;
            3) read -p "Arsitektur (win32/win64): " arch && sed -i "s/ARCH=.*/ARCH=$arch/" "$ANDYOS_DIR/config" ;;
            4) break ;;
        esac
    done
}

# Main
init_andyos
show_menu