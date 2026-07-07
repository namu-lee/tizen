# Workflow: Building Tizen Apps

> Note: Exmaples are based on .NET-SDK 8.0.422 + tizen-workload 10.0.120.

## Install .NET SDK and Tizen workload

1. Install dotnet-sdk-8.0 in `.dotnet`.

    Find a proper version in https://github.com/Samsung/Tizen.NET/blob/main/workload/scripts/version-map.json.
    `workloadVersion` means Tizen's version, and `sdkBand` is a version band of .NET SDK works with it.

    ```bash
    wget https://builds.dotnet.microsoft.com/dotnet/Sdk/8.0.422/dotnet-sdk-8.0.422-linux-x64.tar.gz
    mkdir -p .dotnet
    tar zxf dotnet-sdk-8.0.422-linux-x64.tar.gz -C .dotnet
    ```

1. Install Tizen workload for .NET.

    Reference: https://github.com/Samsung/Tizen.NET/tree/main/workload/scripts

    ```bash
    curl -sSL https://raw.githubusercontent.com/Samsung/Tizen.NET/main/workload/scripts/workload-install.sh | bash -s -- -d $PWD/.dotnet
    ```

    ```bash
    $ dotnet --version
    8.0.422
    $ dotnet workload list

    Installed Workload Id      Manifest Version      Installation Source
    --------------------------------------------------------------------
    tizen                      10.0.126/8.0.400      SDK 8.0.400
    ```

1. Configure `PATH`.

    ```bash
    export PATH=$PWD/.dotnet:$PATH
    ```

## Build and install Tizen apps

1. Build

    ```bash
    cd Tizen-CSharp-Samples/TV
    ./build.sh
    ```

2. Install

    ```bash
    sdb install <path_to_tpk>
    ```
