# Deployment to Service Fabric (Windows, Linux and MacOs) using sfctl
First things first, make sure you have a Service Fabric cluster up and running, either remotely or using the local development environment. Instructions on doing this can be found on the [Service Fabric documentation page](https://docs.microsoft.com/en-gb/azure/service-fabric/).

## Prerequisites
- [sfctl](https://github.com/Azure/service-fabric-cli)

## Instructions
1. Clone this repository to your local machine.
    
    `git clone https://github.com/jjcollinge/traefik-on-service-fabric.git`

2. Download the latest Træfik binary for your architecture from the [releases page](https://github.com/containous/traefik/releases)

    `curl -LOk https://github.com/containous/traefik/releases/download/v1.5.1/traefik_windows-amd64.exe > traefik.exe`

3. Copy the Træfik binary to the expected location

    `cp traefik.exe $REPO_ROOT\Traefik\ApplicationPackageRoot\TraefikPkg\Code\`

   **If you're working against a local development cluster or don't require a secure cluster, skip to step 6.**

4. Træfik must authenticate to the Service Fabric management API. Currently, you can only do this using a PEM formatted client certificate. If you only have a `.pfx` certificate you will need to convert it using the following commands:
    
    * Extract the private key from the `.pfx` file

        `openssl pkcs12 -in $pfxCertFilePath -nocerts -nodes -out "$clientCertOutputDir\servicefabric.key" -passin pass:$certPass`

    * Extract the certificate from the `.pfx` file

        `openssl pkcs12 -in $pfxCertFilePath -clcerts -nokeys -out "clientCertOutputDir\servicefabric.crt" -passin pass:$certPass`
    
    > Træfik *only* requires read-only access to the Service Fabric API and thus you should use a `Read-Only` certificate.

5. Copy your generated certificate files to the `Code\certs` folder Træfik expects to find them in.

    `cp $clientCertOutputDir\* $REPO_ROOT\Traefik\ApplicationPackageRoot\TraefikPkg\Code\certs`

6. Open `$REPO_ROOT\Traefik\Traefik\ApplicationPackageRoot\TraefikPkg\Code\traefik.toml` in a text editor. If you're using a secure cluster, ensure the TLS configuration section is uncommented and make sure the provided certificate paths are correct. Additionally, change the `clustermanagementurl` to use the prefix `https://`.

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

7. *Optional*  You can choose to enable a watchdog service which will report stats and check Træfik is routing correctly by sending synthetic requests and recording the results. The results of these checks are sent to Application Insights. If you would like this enabled follow [the guide here before continuing](../EnableWatchdog.MD).

8. Now we need to connect `sfctl` to our cluster using a suitable authentication method

    `sfctl cluster select --endpoint https://FQDN:19080 --pem /path/to/my/pem/cert.pem --no-verify`

9. We next need to upload our application package to the cluster

    `sfctl application upload --path $REPO_ROOT\Traefik\ApplicationPackageRoot --show-progress`

10. Now provision a type from the uploaded package

    `sfctl application provision --application-type-build-path $REPO_ROOT\Traefik\ApplicationPackageRoot`

11. Finally create a named instance of that package

    `sfctl application create --app-name fabric:/Traefik --app-type TraefikType --app-version 1.0.4`

12. To be able to ingress external requests via Træfik you'll need to open up and map the relevant ports on your public load balancer. For clusters on Azure, this will be your Azure Load Balancer. The default ports are; `tcp/80` (proxy) and `tcp/8080` (API) but these can be configured in `$REPO_ROOT\Traefik\ApplicationPackageRoot\TraefikPkg\Code\traefik.toml` and in `$REPO_ROOT\Traefik\Traefik\ApplicationPackageRoot\TraefikPkg\ServiceManifest.xml`.

13. Once the load balancer has been configured to route traffic on the required ports, you should be able to visit the Træfik dashboard at http[s]://[clusterfqdn]:8080 if you have it enabled.

    ![img](../Images/traefikonsf.png)

> If your cluster does not have any applications deployed, you will see an empty dashboard. **NOTE:** The dashboard will not render in various versions of Internet Explorer.



