# Workflow: Creating Tizen Image

> Note: This instruction is based on Tizen-10.0 / unified-standard / aarch64-headed (build 20251028.114828)

## Option 1: Download from the remote repository

Download images (boot + headed) from the remote.

```bash
# Boot
wget https://download.tizen.org/releases/milestone/TIZEN/Tizen-10.0/Tizen-10.0-Unified/tizen-10.0-unified_20251028.114828/images/standard/tizen-boot-aarch64-rpi/tizen-10.0-unified_20251028.114828_tizen-boot-aarch64-rpi.tar.gz
# Headed
wget https://download.tizen.org/releases/milestone/TIZEN/Tizen-10.0/Tizen-10.0-Unified/tizen-10.0-unified_20251028.114828/images/standard/tizen-headed-aarch64/tizen-10.0-unified_20251028.114828_tizen-headed-aarch64.tar.gz
```

## Option 2: Create an image using locally built packages

1. Download the original kickstart file.

    ```bash
    # Standard-aarch64-rpi (boot + headed)
    wget https://download.tizen.org/releases/milestone/TIZEN/Tizen-10.0/Tizen-10.0-Unified/tizen-10.0-unified_20251028.114828/images/standard/tizen-boot-aarch64-rpi/tizen-10.0-unified_20251028.114828_tizen-boot-aarch64-rpi.ks
    wget https://download.tizen.org/releases/milestone/TIZEN/Tizen-10.0/Tizen-10.0-Unified/tizen-10.0-unified_20251028.114828/images/standard/tizen-headed-aarch64/tizen-10.0-unified_20251028.114828_tizen-headed-aarch64.ks
    ```

1. Edit the `repo` section of the kickstart file (Add the last line to use locally built packages).

    ```text
    repo --name=gbs_repo --baseurl=https://download.tizen.org/releases/milestone/TIZEN/Tizen-10.0/Tizen-10.0-Unified/tizen-10.0-unified_20251028.114828/repos/standard/packages/aarch64/ --ssl_verify=no --priority=99
    repo --name=gbs_base_repo_0 --baseurl=https://download.tizen.org/releases/milestone/TIZEN/Tizen-10.0/Tizen-10.0-Base/tizen-10.0-base_20251028.083647/repos/standard/packages/ --ssl_verify=no --priority=99
    repo --name=local --baseurl=file://<path_to_GBS-ROOT>/local/repos/unified_standard/aarch64/ --priority=1
    ```

1. Create a Tizen image.

    ```bash
    gbs createimage --ks-file=tizen-10.0-unified_20251028.114828_tizen-headed-aarch64.ks
    ```
