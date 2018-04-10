# Contributing to Traefik on Service Fabric

> **Warning:**
Developing this solution is a non-trivial task especially if you are unfamiliar with the `golang`, [`dep`](https://github.com/golang/dep) and its tooling. We highly recommend taking the time to understand both `dep` and `golang` on a simpler project before starting.  

## Requirements

- Golang Environment: [Guide](https://golang.org/doc/install) *NOTE*: Ensure you have your [GOPATH](https://github.com/golang/go/wiki/GOPATH) and other required environment variables configured.
- Docker Installed
- Dep Installed: [Install Guide](https://github.com/golang/dep) and [How-to](https://golang.github.io/dep/docs/introduction.html)
- Local Service Fabric cluster: [Mac](https://docs.microsoft.com/en-us/azure/service-fabric/service-fabric-get-started-mac) or [Windows](https://docs.microsoft.com/en-us/azure/service-fabric/service-fabric-get-started)
- [Sample Application](https://azure.microsoft.com/en-us/resources/samples/service-fabric-dotnet-getting-started/) deployed into Service Fabric cluster
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

### Optional but recommended

- VSCode with [Go Extension](https://github.com/microsoft/vscode-go)
- [Delve](https://github.com/Microsoft/vscode-go/wiki/Debugging-Go-code-using-VS-Code) debugger installed and configured 

## Introduction

In this doc we will focus building out your dev environment and assume a working knowledge of the SF provider and Traefik. 

[This blog](https://blogs.msdn.microsoft.com/azureservicefabric/2018/04/05/intelligent-routing-on-service-fabric-with-traefik/) provides a good understanding of how the integration works and why it was written. It is highly recommended that you read the blog and [Traefik docs](https://docs.traefik.io/) before proceeding. 

The solution consists of several different github projects:

- [Traefik Extra Service Fabric](https://github.com/containous/traefik-extra-service-fabric): SF provider for Traefik
- [Service Fabric Go SDK](https://github.com/jjcollinge/servicefabric): SF Management SDK for Go
- [Traefik](https://github.com/containous/traefik): Builds the proxy  

The `Traefik` project imports `Traefik Extra Service Fabric` which in turn import the `Service Fabric Golang SDK` all using `dep` and versioned by CommitID pinning. 

To release an update of the `Service Fabric Golang SDK` a pull-request (PR) should be made to it's repository and once accepted `Traefik Extra Service Fabric`'s `gopkg.toml` can be update to reference this new CommitID and this change is PR'd. Then finally `Traefik` can be updated to reference this new version of `Traefik Extra Service Fabric`. While this provides the necessary control to version releases of `Traefik` this isn't a workable flow when developing.  

## Recommended Dev Setup

For local development you can simplify the flow by cloning both `Traefik Extra Service Fabric` and `Service Fabric Go SDK` into the `/vendor` folder of `Traefik`.

> **NOTE:** `master` of `Traefik Extra Service Fabric` is compatible with the latest `Traefik` release so checkout the right `Traefik` branch, eg. `v1.6` not `master`. 

This provides a quick and easy way to build/debug `Traefik` by making changes to `Traefik Extra Service Fabric` in the `/vendor` folder. These changes can then be checked in an pushed from each projects folder `/vendor/github.com/jjcollinge/servicefabric` for example. **Note** This is only a local solution to speed things up, the full flow is required for releases. 

> **NOTE:** Be aware that `golang` is sensitive to file paths so, even if you are working on a fork, you must ensure your `Traefik` instance is located at `$gopath/src/github.com/containous/traefik`

> **NOTE:** If you do work inside `Traefik`'s `/vendor` directory, it may be helpful to delete the `.git` folder inside `Traefik` to avoid confusion between the nested git repositories.


Assuming `~/scratch` is your `gopath` then this will look roughly like this: 

```
 
~/scratch >> mkdir -p src/github.com/containous/traefik
~/scratch >> cd src/github.com/containous/traefik
~/scratch/src/github.com/containous>> git clone https://github.com/containous/traefik/

    Cloning into 'traefik'...
    remote: Counting objects: 27505, done.
    remote: Compressing objects: 100% (300/300), done.
    remote: Total 27505 (delta 213), reused 459 (delta 175), pack-reused 26876
    Receiving objects: 100% (27505/27505), 25.92 MiB | 2.17 MiB/s, done.
    Resolving deltas: 100% (14236/14236), done.
    Checking out files: 100% (4772/4772), done.

~/scratch/src/github.com/containous>> cd traefik
~/scratch/src/github.com/containous>> git checkout v1.6 && cd ./traefik/vendor/github.com/containous
~/scratch/src/github.com/containous/traefik/vendor/github.com/containous >> rm -r traefik-extra-service-fabric
 ~/scratch/src/github.com/containous/traefik/vendor/github.com/containous >> git clone https://github.com/containous/traefik-extra-service-fabric

    Cloning into 'traefik-extra-service-fabric'...
    remote: Counting objects: 313, done.
    remote: Compressing objects: 100% (25/25), done.
    remote: Total 313 (delta 15), reused 21 (delta 12), pack-reused 276
    Receiving objects: 100% (313/313), 102.33 KiB | 548.00 KiB/s, done.
    Resolving deltas: 100% (171/171), done.
~/scratch/src/github.com/containous/traefik/vendor/github.com/containous >> cd ../jjcollinge

~/scratch/src/github.com/containous/traefik/vendor/github.com/jjcollinge >> rm -r servicefabric
~/scratch/src/github.com/containous/traefik/vendor/github.com/jjcollinge >> git clone https://github.com/jjcollinge/servicefabric

    Cloning into 'servicefabric'...
    remote: Counting objects: 93, done.
    remote: Total 93 (delta 0), reused 0 (delta 0), pack-reused 93
    Unpacking objects: 100% (93/93), done

~/scratch/src/github.com/containous/traefik/vendor/github.com/jjcollinge>> cd ../../../
~/scratch/src/github.com/containous/traefik> go build ./cmd/traefik

```

## Building & Testing

### Traefik

1. Follow [Traefik WebUI Build](https://github.com/containous/traefik/tree/master/webui#how-to-build-for-backends-developer): How to build for backend devs 

    **NOTE**: If you have an empty `/static` folder already delete it before running `make generate-ui`. This may fail on Windows, if so, please use a `bash` environment such as [WSL](https://docs.microsoft.com/en-us/windows/wsl/install-win10).

2. Follow the [Traefik Guide](https://github.com/containous/traefik/blob/master/CONTRIBUTING.md#method-2-using-go): Method #2 

### Testing `Traefik Extra Service Fabric` and the SDK

In the `traefik` directory run:
``` 
    go test -v ./vendor/github.com/containous/traefik-extra-service-fabric/...
    go test -v ./vendor/github.com/jjcollinge/servicefabric/...
```

## Debugging using VSCode

In your `Traefik` directory create the following files then hit `F5`. You can step and set breakpoints in both `Traefik` and the other packages in the `vendor` file.

`.vscode/launch.json`
``` json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug Launch",
            "type": "go",
            "request": "launch",
            "mode": "debug",
            "port": 2345,
            "host": "127.0.0.1",
            "program": "${workspaceRoot}/cmd/traefik",
            "args": [
                "--configfile=./.vscode/testconfig.toml",
            ],
            "showLog": true
        }
    ]
}
```

`.vscode/testconfig.toml`
``` toml
################################################################
# Global configuration
################################################################

# Enable debug mode
#
# Optional
# Default: false
#
debug = true

# Log level
#
# Optional
# Default: "ERROR"
#
logLevel = "DEBUG"

################################################################
# Entrypoints configuration
################################################################

# Entrypoints definition
#
# Optional
# Default:
[entryPoints]
    [entryPoints.http]
    address = ":8081"
    [entryPoints.traefik]
    address = ":8080"



################################################################
# API and dashboard configuration
################################################################

# Enable API and dashboard
[api]

  # Name of the related entry point
  #
  # Optional
  # Default: "traefik"
  #
  # entryPoint = "traefik"

  # Enabled Dashboard
  #
  # Optional
  # Default: true
  #
  # dashboard = false

################################################################
# Ping configuration
################################################################

# Enable ping
[ping]

  # Name of the related entry point
  #
  # Optional
  # Default: "traefik"
  #
  # entryPoint = "traefik"

################################################################
# Service Fabric provider
################################################################

# Enable Service Fabric configuration backend
[servicefabric]

# Service Fabric Management Endpoint
clustermanagementurl = "http://localhost:19080"
# Note: use "https://localhost:19080" if you're using a secure cluster

# Service Fabric Management Endpoint API Version
apiversion = "3.0"

# Enable TLS connection.
#
# Optional
#
#[serviceFabric.tls]
#  cert = "certs/servicefabric.crt"
#  key = "certs/servicefabric.key"
#  insecureskipverify = true

```