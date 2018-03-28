# Deployment to Service Fabric (Windows) using Visual Studio
First things first, make sure you have a Windows Service Fabric cluster up and running, either remotely or using the local development environment. Instructions on doing this can be found on the [Service Fabric documentation page](https://docs.microsoft.com/en-gb/azure/service-fabric/).

## Prerequisites
- Visual Studio 2015 or greater with Service Fabric tooling.
- OpenSSL for Windows

## Instructions
1. Clone this repository to your local machine.
    
    `git clone https://github.com/jjcollinge/traefik-on-service-fabric.git`

2. Download the Træfik binary into the solution by running the following PowerShell script.

    `./$REPO_ROOT/Traefik/Scripts/Get-TraefikBinary.ps1 -url $TRAEFIK_RELEASE`

    > This script requires a `url` to be provided to the Træfik release you wish to download and install. A list of the available release are here: https://github.com/containous/traefik/releases.

3. Open the `Traefik.sln` file in Visual Studio

    **If you're working against a local development cluster or don't require a secure cluster, skip to step 7.**

4. Træfik must authenticate to the Service Fabric management API. Currently, you can only do this using a PEM formatted client certificate. If you only have a `.pfx` certificate you will need to convert it using the following commands:
    
    * Extract the private key from the `.pfx` file

        `openssl pkcs12 -in $pfxCertFilePath -nocerts -nodes -out "$clientCertOutputDir\servicefabric.key" -passin pass:$certPass`

    * Extract the certificate from the `.pfx` file

        `openssl pkcs12 -in $pfxCertFilePath -clcerts -nokeys -out "clientCertOutputDir\servicefabric.crt" -passin pass:$certPass`
    
    > Træfik *only* requires read-only access to the Service Fabric API and thus you should use a `Read-Only` certificate.

5. Copy your generated certificate files to the `Code\certs` folder Træfik expects to find them in.

    `cp $clientCertOutputDir\* $REPO_ROOT\Traefik\ApplicationPackageRoot\TraefikPkg\Code\certs`

6. If you wish to track the new certificate files in Visual Studio, you'll need to add them to your solution by right clicking on the `$REPO_ROOT\Traefik\ApplicationPackageRoot\TreafikPkg\Code\certs` folder and selecting `Add Existing Item...`, navigate to the certificates on local disk and select `Add`.

7. Open `$REPO_ROOT\Traefik\Traefik\ApplicationPackageRoot\TraefikPkg\Code\traefik.toml` in a text editor. If you're using a secure cluster, ensure the TLS configuration section is uncommented and make sure the provided certificate paths are correct. Additionally, change the `clustermanagementurl` to use the prefix `https://`. 

> The `clustermanagementurl` setting is relative to where Træfik is running. If Træfik is running inside the cluster on every node, the `clustermanagementurl` should be left as `http[s]://localhost:19080`, if however, Træfik is running externally to the cluster, an accessible endpoint should be provided. If you are testing Træfik against an unsecure cluster, like your local onebox cluster, use `http://localhost:19080`

```toml
################################################################
# Service Fabric provider
################################################################

# Enable Service Fabric configuration backend
[servicefabric]

# Service Fabric Management Endpoint
clustermanagementurl = "https://localhost:19080"

# Service Fabric Management Endpoint API Version
apiversion = "3.0"

# Enable TLS connection.
#
# Optional
#
 [serviceFabric.tls]
   cert = "certs/servicefabric.crt"
   key = "certs/servicefabric.key"
   insecureskipverify = true
```

8. *Optional*  You can choose to enable a watchdog service which will report stats and check Træfik is routing correctly by sending synthetic requests and recording the results. The results of these checks are sent to Application Insights. If you would like this enabled follow [the guide here before continuing](../EnableWatchdog.MD).

9. You can now simply publish Træfik from Visual Studio like any other Service Fabric application. Right click on the project, select `Publish` and follow the publication wizard. 

10. To be able to ingress external requests via Træfik you'll need to open up and map the relevant ports on your public load balancer. For clusters on Azure, this will be your Azure Load Balancer. The default ports are; `tcp/80` (proxy) and `tcp/8080` (API) but these can be configured in `$REPO_ROOT\Traefik\ApplicationPackageRoot\TraefikPkg\Code\traefik.toml` and in `$REPO_ROOT\Traefik\Traefik\ApplicationPackageRoot\TraefikPkg\ServiceManifest.xml`.

11. Once the load balancer has been configured to route traffic on the required ports, you should be able to visit the Træfik dashboard at http[s]://[clusterfqdn]:8080 if you have it enabled.

    ![img](../Images/traefikonsf.png)

> If your cluster does not have any applications deployed, you will see an empty dashboard. **NOTE:** The dashboard will not render in various versions of Internet Explorer.