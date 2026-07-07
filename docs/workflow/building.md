# Workflow: Building Tizen Repositories

> Note: This instruction is based on Tizen-10.0 / unified-standard / aarch64-headed (build 20251028.114828)

## Install GBS and MIC

* Git Build System (GBS)
* Image Creator (MIC)

1. Add Tizen repository in the apt list.

    ```bash
    echo "deb [trusted=yes] http://download.tizen.org/tools/latest-release/Ubuntu_$(lsb_release -rs)/ /" | \
    sudo tee /etc/apt/sources.list.d/tizen.list > /dev/null
    ```

1. Install `gbs` and `mic`.

    ```bash
    sudo apt-get update && sudo apt-get install -y gbs mic
    ```

## Configure GBS

Create `.gbs.conf` and write the below configuration in it.

```text
[general]
fallback_to_native = true
profile = profile.unified_standard
buildroot = .GBS-ROOT

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

## Configure SSH

1. Add a SSH key to Tizen [Gerrit](https://review.tizen.org).

1. Add an SSH configuation in `$HOME/.ssh/config`.

    ```
    Host tizen review.tizen.org
    Hostname review.tizen.org
    IdentityFile <private_key>
    User <Gerrit_Username>
    Port 29418
    ```

1. Test connection.

    ```bash
    $ ssh tizen
    **** Welcome to Gerrit Code Review ****
    ```

## Option 1: Clone and build a single repository

1. Clone a repository.

    ```bash
    git clone --branch <branch> <repo_url>

    # Example:
    git clone --branch tizen_10.0_release "git://review.tizen.org/git/platform/core/dotnet/launcher"
    ```

1. Build the repository.

    <!-- > To speed up the build process, mount `BUILD-ROOTS` directory as a ram disk. (Required RAM & SWAP > 8GB)
    >
    > ```bash
    > mkdir -p ../.GBS-ROOT/local/BUILD-ROOTS
    > sudo mount -t tmpfs -o size=16G tmpfs ../.GBS-ROOT/local/BUILD-ROOTS
    > ``` -->

    ```bash
    cd <repository>
    git switch --detach tizen_10.0_release # Optional
    gbs -c ../.gbs.conf build -P unified_standard -A aarch64 --buildroot ../.GBS-ROOT
    cd ../
    ```

### Installing the built RPM package

A built RPM can be installed on the running Tizen device using `sdb`.

1. Push the built RPM into the device.

    ```bash
    sdb connect 192.168.1.11
    sdb root on
    sdb push .GBS-ROOT/local/repos/unified_standard/aarch64/RPMS/<name>.rpm /tmp/
    ```

1. Resize the root filesystem and re-mount it with a write permission.

    ```bash
    resize2fs /dev/mmcblk0p2
    mount -o remount,rw /
    ```

1. Install the RPM.

    ```bash
    rpm -Uvh --replacepkgs --replacefiles /tmp/dotnet-launcher-8.0.11-1.aarch64.rpm
    ```

1. Verify the installation.

    ```bash
    $ echo $?
    0
    $ date
    Tue Jul  7 17:20:52 KST 2026
    $ rpm -qi dotnet-launcher | grep "Install Date"
    Install Date: Tue Jul  7 17:19:55 2026
    ```

## Option 2: Clone and build all repositories

### Setup `repo` tool

1. Create a local bin directory.

    ```bash
    mkdir ~/bin/
    PATH=~/bin:$PATH
    ```

2. Download `repo` tool.

    ```bash
    curl http://commondatastorage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
    sudo chmod a+x ~/bin/repo
    ```

### Clone and build all packages

1. Initialize `.repo/`.

    ```bash
    repo init -u ssh://<Gerrit_Username>@review.tizen.org:29418/scm/manifest -b tizen -m unified_standard.xml
    ```

1. Download manifests.

    ```bash
    wget https://download.tizen.org/releases/milestone/TIZEN/Tizen-10.0/Tizen-10.0-Unified/tizen-10.0-unified_20251028.114828/builddata/manifest/tizen-10.0-unified_20251028.114828_standard.xml -O .repo/manifests/unified/standard/projects.xml
    ```

    > A specific repository (e.g., `chromium-efl`) can be excluded from the manifest.
    >
    > ```bash
    > mkdir -p .repo/local_manifests
    > echo "<?xml version="1.0" encoding="UTF-8"?>
    > <manifest>
    >   <remove-project name="platform/framework/web/chromium-efl" />
    > </manifest>" >> .repo/local_manifests/excludes.xml
    > ```

1. Sync the repository.

    ```bash
    repo sync --no-manifest-update -c --no-tags -j16
    ```

    * `--no-manifest-update`: Do not update the manifest checkout
    * `-c`: Fetch current branch only
    * `--no-tags`: Do not fetch tags
    * `-jN`: N jobs

1. Build the repository.

    ```bash
    gbs -c .gbs.conf build \
        -P unified_standard \
        -A aarch64 \
        --threads 16 \
        --define "_smp_mflags -j8" \
        --baselibs \
        --clean-once \
        --skip-srcrpm \
        --buildroot .GBS-ROOT
    ```
