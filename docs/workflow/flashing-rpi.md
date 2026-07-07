# Workflow: Flashing Raspberry Pi 5

## Install Tizen studio SDK

1. Download Tizen studio SDK installer.

    ```bash
    wget https://download.tizen.org/sdk/Installer/tizen-sdk_10.0/web-cli_Tizen_SDK_10.0_ubuntu-64.bin
    chmod +x web-cli_Tizen_SDK_10.0_ubuntu-64.bin
    ```

1. Install Tizen studio SDK.

    ```bash
    mkdir -p .tizen-studio
    ./web-cli_Tizen_SDK_10.0_ubuntu-64.bin --accept-license $PWD/.tizen-studio
    ```

1. Configure `PATH`.

    ```bash
    export TIZEN_STUDIO=$PWD/.tizen-studio
    export PATH=$TIZEN_STUDIO/tools:$TIZEN_STUDIO/package-manager:$PATH
    ```

## Flash an SD card

1. Clone tizen-fusing-scripts.

```bash
git clone git://review.tizen.org/git/platform/kernel/tizen-fusing-scripts -b tizen
```

1. Flash the SD card using the script.

    ```bash
    export SDCARD=/dev/sdX
    sudo tizen-fusing-scripts/scripts/sd_fusing.py -d $SDCARD -t rpi4 --format
    sudo tizen-fusing-scripts/scripts/sd_fusing.py -d $SDCARD -t rpi4 -b tizen-10.0-unified_20251028.114828_tizen-boot-aarch64-rpi.tar.gz tizen-10.0-unified_20251028.114828_tizen-headed-aarch64.tar.gz
    sudo bash inject-static-ip.sh $SDCARD
    ```

## Boot RPI and connect to SDB

1. Connect LAN between the host and rpi.
1. Manually configure the host ip.

    ```text
    IP = 192.168.1.1
    SUBNET_MASK = 255.255.255.0
    GATEWAY = 192.168.1.2
    ```

1. Connect to sdb.

    ```bash
    sdb connect 192.168.1.11
    sdb root on
    sdb shell
    ```
