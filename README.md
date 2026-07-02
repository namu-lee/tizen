# Tizen Development Environment Setup

Reference: https://github.com/Samsung/tizen-docs/tree/master/docs/platform/developing

## Install tools

* Git Build System (GBS)
* Image Creator (MIC)

1. Add Tizen repository in the apt list.

```bash
echo "deb [trusted=yes] http://download.tizen.org/tools/latest-release/Ubuntu_$(lsb_release -rs)/ /" | \
sudo tee /etc/apt/sources.list.d/tizen.list > /dev/null
```

2. Install gbs and mic.

```bash
sudo apt-get update && sudo apt-get install gbs mic
```

## Setup `repo` tool

1. Create a local bin directory.

```bash
mkdir ~/bin/
PATH=~/bin:$PATH
```

2. Download `repo` tool.

```bash
curl http://commondatastorage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
```

3. Change permissions

```bash
sudo chmod a+x ~/bin/repo
```

## Configure SSH

Add a SSH key to Tizen [Gerrit](https://review.tizen.org)

```
Host tizen review.tizen.org
Hostname review.tizen.org
IdentityFile ~/.ssh/id_rsa
User <Gerrit_Username>
Port 29418
```

```bash
$ ssh tizen
**** Welcome to Gerrit Code Review ****
```

## Clone tizen repository

> Note: This instruction is based on Tizen-10.0 / unified-emulator (build 20251028.11482)

1. Initialize `.repo/`.

```bash
mkdir ~/tizen/emulator && cd ~/tizen/emulator
repo init -u ssh://sanghyeon@review.tizen.org:29418/scm/manifest -b tizen -m unified_emulator.xml
```

2. Download manifests.

```bash
wget https://download.tizen.org/releases/milestone/TIZEN/Tizen-10.0/Tizen-10.0-Unified/tizen-10.0-unified_20251028.114828/builddata/manifest/tizen-10.0-unified_20251028.114828_emulator.xml -O .repo/manifests/unified/emulator/projects.xml
```

3. Exclude `chromium-efl` repository from the manifest.

```bash
mkdir -p .repo/local_manifests
echo "<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <remove-project name="platform/framework/web/chromium-efl" />
</manifest>" >> .repo/local_manifests/excludes.xml
```


4. Sync the repo.

```
repo sync --no-manifest-update -c --no-tags -j16
```

* `--no-manifest-update`: Do not update the manifest checkout
* `-c`: Fetch current branch only
* `--no-tags`: Do not fetch tags
* `-jN`: N jobs

## Configure GBS

Create `.gbs.tizen-10.conf` and write the below configuration in it.

```
[general]
fallback_to_native = true
profile = profile.unified_emulator
buildroot = /home/sanghyeon/tizen/GBS-ROOT/

#########################################################
################## Profile Section ##################
#########################################################

############# unified #############
[profile.unified_standard]
repos = repo.base_standard,repo.base_standard_debug,repo.unified_standard,repo.unified_standard_debug

[profile.unified_emulator]
repos = repo.base_standard,repo.base_standard_debug,repo.unified_emulator,repo.unified_emulator_debug

#########################################################
################## Repo Section##################
#########################################################

############# base #############
[repo.base_standard]
url = https://download.tizen.org/releases/milestone/TIZEN/Tizen-10.0/Tizen-10.0-Base/tizen-10.0-base_20251028.083647/repos/standard/packages/
[repo.base_standard_debug]
url = https://download.tizen.org/releases/milestone/TIZEN/Tizen-10.0/Tizen-10.0-Base/tizen-10.0-base_20251028.083647/repos/standard/debug/

############# unified #############
[repo.unified_standard]
url = https://download.tizen.org/releases/milestone/TIZEN/Tizen-10.0/Tizen-10.0-Unified/tizen-10.0-unified_20251028.114828/repos/standard/packages/
[repo.unified_standard_debug]
url = https://download.tizen.org/releases/milestone/TIZEN/Tizen-10.0/Tizen-10.0-Unified/tizen-10.0-unified_20251028.114828/repos/standard/debug/

[repo.unified_emulator]
url = https://download.tizen.org/releases/milestone/TIZEN/Tizen-10.0/Tizen-10.0-Unified/tizen-10.0-unified_20251028.114828/repos/emulator/packages/
[repo.unified_emulator_debug]
url = https://download.tizen.org/releases/milestone/TIZEN/Tizen-10.0/Tizen-10.0-Unified/tizen-10.0-unified_20251028.114828/repos/emulator/debug/
```

## Build all packages

```bash
cd ~/<PROJECT_DIR>
gbs -c /home/sanghyeon/tizen/emulator/.gbs.tizen-10.conf build\
    -P unified_emulator \
    -A x86_64 \
    --threads 16 \
    --define "_smp_mflags -j8" \
    --include-all \
    --baselibs \
    --clean-once \
    --skip-srcrpm
```

## Create an image

1. Download the original kickstart file.

```bash
# Emulator
wget https://download.tizen.org/releases/milestone/TIZEN/Tizen-10.0/Tizen-10.0-Unified/tizen-10.0-unified_20251028.114828/images/emulator/tizen-headed-emulator64-wayland/tizen-10.0-unified_20251028.114828_tizen-headed-emulator64-wayland.ks

# Standard-aarch64-rpi (boot + headed)
wget https://download.tizen.org/releases/milestone/TIZEN/Tizen-10.0/Tizen-10.0-Unified/tizen-10.0-unified_20251028.114828/images/standard/tizen-boot-aarch64-rpi/tizen-10.0-unified_20251028.114828_tizen-boot-aarch64-rpi.ks
wget https://download.tizen.org/releases/milestone/TIZEN/Tizen-10.0/Tizen-10.0-Unified/tizen-10.0-unified_20251028.114828/images/standard/tizen-headed-aarch64/tizen-10.0-unified_20251028.114828_tizen-headed-aarch64.ks
```

2. Edit the `repo` section of the kickstart file. (Add the last line)

```
repo --name=gbs_repo --baseurl=https://download.tizen.org/releases/milestone/TIZEN/Tizen-10.0/Tizen-10.0-Unified/tizen-10.0-unified_20251028.114828/repos/emulator/packages/ --ssl_verify=no --priority=99
repo --name=gbs_base_repo_0 --baseurl=https://download.tizen.org/releases/milestone/TIZEN/Tizen-10.0/Tizen-10.0-Base/tizen-10.0-base_20251028.083647/repos/standard/packages/ --ssl_verify=no --priority=99
repo --name=local --baseurl=file:///home/sanghyeon/tizen/GBS-ROOT/local/repos/unified_emulator/x86_64/ --priority=1
```

3. Create a Tizen image

```bash
gbs createimage --tmpfs --ks-file=tizen-10.0-unified_20251028.114828_tizen-headed-emulator64-wayland.ks
```

* `--tmpfs`: Use it to speed up the image creation if there are more than 4GB RAM available.

## Install tizen studio

```bash
export TIZEN_STUDIO=$HOME/tizen/tizen-studio
export PATH=$TIZEN_STUDIO/tools:$TIZEN_STUDIO/tools/emulator/bin:$TIZEN_STUDIO/package-manager:$PATH
```

```bash
sudo apt install -y libkf5itemmodels5 libkf5kiowidgets5 libkchart2 acl libsdl1.2debian bridge-utils openvpn libv4l-0t64
package-manager-cli.bin install --accept-license Emulator
package-manager-cli.bin install --accept-license TIZEN-10.0-Emulator
```

Enable KVM.

```bash
sudo apt install -y qemu-kvm cpu-checker
sudo usermod -aG kvm "$USER"
newgrp kvm
```

Enable HW virtualization in `tizen-studio-data/emulator/vms/T-10.0-x86_64/vm_config.xml`.

```xml
<hwVirtualization>true</hwVirtualization>
```

## Flashing RPI

```bash
wget https://download.tizen.org/releases/milestone/TIZEN/Tizen-10.0/Tizen-10.0-Unified/tizen-10.0-unified_20251028.114828/images/standard/tizen-boot-aarch64-rpi/tizen-10.0-unified_20251028.114828_tizen-boot-aarch64-rpi.tar.gz
wget https://download.tizen.org/releases/milestone/TIZEN/Tizen-10.0/Tizen-10.0-Unified/tizen-10.0-unified_20251028.114828/images/standard/tizen-headed-aarch64/tizen-10.0-unified_20251028.114828_tizen-headed-aarch64.tar.gz

git clone git://review.tizen.org/git/platform/kernel/tizen-fusing-scripts -b tizen
sudo tizen-fusing-scripts/scripts/sd_fusing.py -d /dev/sdX -t rpi4 --format
sudo tizen-fusing-scripts/scripts/sd_fusing.py -d /dev/sdX -t rpi4 -b tizen-10.0-unified_20251028.114828_tizen-boot-aarch64-rpi.tar.gz tizen-10.0-unified_20251028.114828_tizen-headed-aarch64.tar.gz
sudo bash inject-static-ip.sh /dev/sdX
```

## Booting and Connecting SDB

1. Connect LAN between the host and rpi.
2. Manually configure the host ip.

```text
IP = 192.168.1.1
SUBNET_MASK = 255.255.255.0
GATEWAY = 192.168.1.2
```

3. Connect to sdb.

```bash
sdb connect 192.168.1.11
sdb root on
sdb shell
```

## Build Tizen Apps

1. Install dotnet-sdk-8.0 in `.dotnet`.

Find a proper version in https://github.com/Samsung/Tizen.NET/blob/main/workload/scripts/version-map.json.
`workloadVersion` means Tizen's version, and `sdkBand` is a version band of .NET SDK works with it.

2. Install Tizen workload (Reference: https://github.com/Samsung/Tizen.NET/tree/main/workload/scripts)

```bash
curl -sSL https://raw.githubusercontent.com/Samsung/Tizen.NET/main/workload/scripts/workload-install.sh | bash -s -- -d $HOME/tizen/.dotnet
```
