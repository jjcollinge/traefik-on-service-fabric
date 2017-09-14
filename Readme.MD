# Running Traefik on Service Fabric

# What is Traefik?
Træfik (pronounced like traffic) is a modern HTTP reverse proxy and load balancer made to deploy microservices with ease. It supports several backends (Docker, Swarm mode, Kubernetes, Marathon, Consul, Etcd, Rancher, Amazon ECS, and a lot more) to manage its configuration automatically and dynamically.
For more information, visit the [Traefik homepage](https://traefik.io/)

# What is Service Fabric?
Azure Service Fabric is a distributed systems platform that makes it easy to package, deploy, and manage scalable and reliable microservices and containers.
For more information, visit the [Service Fabric homepage](https://azure.microsoft.com/en-gb/services/service-fabric/)

# Why run Traefik on Service Fabric?
Integrating Treafik and Service Fabric allows you to configure much more advanced, yet flexible, traffic routing scenarios for your Service Fabric hosted services and applications. You get all the benefits of using Treafik to configure your routing whilst also getting the benefits of Service Fabric's packaging model.

# How do I get started?
First things first, make sure you have a Service Fabric cluster up and running, either remotely or using the local development environment. Instructions on doing this can be found on the [Service Fabric documentation page](https://docs.microsoft.com/en-gb/azure/service-fabric/).

Once you have a Service Fabric cluster up and running, let's deploy a sample application so you have something to route traffic to. The [Service Fabric Getting Started Sample](https://azure.microsoft.com/en-us/resources/samples/service-fabric-dotnet-getting-started/) is a great starting point. This application contains services for each of the supported service types (Stateless services, Stateful services, Actors services and Guest Executable services [Currently there is no container service although Service Fabric does have support for this type of service]). Once you've deployed the sample application to your cluster we can get started working with Traefik.

1. Clone this repository to your local machine.
    
    `git clone https://github.com/jjcollinge/traefik-on-service-fabric.git`

2. Open the `Traefik.sln` file in Visual Studio

If you're working against a local development cluster skip to step 9.

3. Download or copy your clusters `.pfx` certificate file into the folder `traefik-on-service-fabric\Traefik\Scripts\`. If you have multiple certificates, this should be the one you wish Traefik to use to authenticate against your cluster's management endpoint. Ideally, this will be a `read-only` certificate.

4. Set your execution policy to unrestricted to allow the scripts to run
`Set-ExectuionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser`

5. Create a passphrase ANSI text file with suitable permissions and write the .Pfx passphrase to it.

6. Please read to the [Certificates section](#certificates) before running the `Create-Certs.ps1` script. 

`.\Create-Certs.ps1 -PfxCertFilePath <myclustercert.pfx> -PfxPassphraseFilePath <mypassphrase.txt> -CASubject "/C=GB/ST=England/L=London/O=Jon/CN=www.example.com"`

7. Copy your generated certificate to the folder Traefik expects to find them in `traefik-on-service-fabric\Traefik\ApplicationPackageRoot\TraefikPkg\Code\certs`

`cp .\certs\* ..\ApplicationPackageRoot\TraefikPkg\Code\certs\`

8. If you wish to track the new certificate files in Visual Studio, you'll need to add them to your solution by right clicking on the `ApplicationPackageRoot\TreafikPkg\Code\certs` folder and selecting `Add Existing Item...`, navigate to the certificates local on disk and select `Add`.

9. Edit the `traefik-on-service-fabric\Traefik\ApplicationPackageRoot\TraefikPkg\Code\traefik.toml` configuration file. If you're using a secure cluster, uncomment the 3 certificate parameters and make sure they point to the file names we generated earlier. Finally, ensure the `clustermanagementurl` is correct and that the `[servicefabric] provider tag is uncommented.

```toml
################################################################
# Service Fabric provider
################################################################

# Enable Service Fabric configuration backend
[servicefabric]

# Service Fabric Management Endpoint
clustermanagementurl = "http://localhost:19080"

# Service Fabric Management Endpoint API Version
apiversion = "3.0"

# Client certifcate file path
# clientcertfilepath = "certs/mycert.crt"

# Client certifcate key file path
# clientcertkeyfilepath = "certs/mycert.key"

# CA certifcate file path
# cacertfilepath = "certs/cacert.cer"
```

10. You now have a choice (Jikes!). See [simple configuration](#simple-configuration) or [advanced configuration](#advanced-configuration)

11. Once configured, you can simply publish Traefik from Visual Studio like any other Service Fabric service.

12. To be able to route traffic through the Traefik API and see the dashboard, you'll need to open up and map the relevant ports on the Azure Load Balancer. These ports default to 80 (API) and 8080 (Dashboard) and can be configured in the `traefik-on-service-fabric\Traefik\ApplicationPackageRoot\TraefikPkg\Code\traefik.toml` file and the TraefikPkg's `ServiceManifest.xml`.

13. Once the deployment is complete, you should be able to visit the Traefik dashboard at http[s]://[clusterfqdn]:8080.

![img](Docs/Images/traefikonsf.png)

14. Now that you have a Traefik instance up and running, you can simply update the config by changing either the `ApplicationParameters` or `...traefik.toml` and then running the `traefik-on-service-fabric\Traefik\Scripts\Update-Config.ps1`. This will patch your configuration files (`ApplicationManifest.xml` and `ServiceManifest.xml`), create a config-only Service Fabric application package and kick off a rolling update.

## How does it work?

Traefik is hosted as a Service Fabric Guest Executable. Traefik has a built in Service Fabric [provider](https://github.com/containous/traefik/tree/master/provider) which will query the Service Fabric management API to discover what services are currently being hosted in the cluster (referred to as `backends`). The provider then maps routing rules (known as `frontends`) across these `backends`. Traffic then flows in via `entrypoints` (http, https, etc.), the `frontends` are then applied to load balance and filter traffic to each `backend`. The provider will take into account the `Health` and `Status` of each of the services to ensure traffic is only routed to healthy service instances.

To learn more about the Traefik model of Frontends and Backends [see their documentation](https://docs.traefik.io/basics/).

## Simple Configuration

The simplest way to expose a Service Fabric service via Traefik is by using Service Fabric's `ApplicationParameters`. 

1. Add a default parameter to your `ApplicationPackageRoot/ApplicationManifest.xml`

```xml
<Parameters>
    ...
    <Parameter Name="TraefikPublish" DefaultValue="" />
    ...
</Parameters>
```

2. Under the `..\ApplicationParameters\` directory you will find a few files. Depending on your intended target `local` or `cloud` you'll need to edit the appropriate file i.e. `Local.5node.xml`. Add a parameter with the name `TraefikPublish` and the value as a comma seperated list of service names you wish to expose.

```xml
<Parameters>
    ...
    <Parameter Name="TraefikPublish" Value="fabric:/GettingStartedApplication/WebService" />
    ...
</Parameters>
```

## Advanced Configuration

Traefik has a more advanced features than simple routing, including [Rate limiting](https://docs.traefik.io/basics/#backends) and [Circuit breakers](https://docs.traefik.io/basics/#backends) for backends and [Modifiers](https://docs.traefik.io/basics/#frontends) and [Matchers](https://docs.traefik.io/basics/#matchers) for frontends.

These can all be used and customised when deploying on Service Fabric through a configuration template file. The template file is used to generate a TOML file which configures the Traefik instance. Here are some [examples of Traefik TOML files](https://docs.traefik.io/user-guide/examples/).

When configuring your template files, please note that the Service Fabric Traefik provider will dynamically inject your service endpoints as backend servers. This means you can add configuration such as load balancing rules which will be applied to the injected servers at runtime.

More detail on using the templates can be found [here](Docs/CustomTemplates.MD), along with [samples here](Docs/SampleTemplates).

## Certificates
The `Create-Certs.ps1` script is intended to help bootstrap a simple Traefik deployment to a Service Fabric cluster by generating PEM formatted certificate files from an existing .Pfx certificate. However, it is not intended as a production-grade solution for securing Traefik.
I recommend you read the [documentation](https://docs.microsoft.com/en-us/azure/service-fabric/service-fabric-cluster-security-update-certs-azure) on managing certificates in Azure Service Fabric.

The Traefik provider only requires `Read-Only` access to the Service Fabric API and thus you should ideally use a `Read-Only` certificate.

The `Create-Certs.ps1` script also generates a root CA certificate signed with the same client key. If you require this to be signed by an offical CA or a different key then please comment out this section of the script and manually obtain the root CA certificate.

Currently, the script has to unencrypt the .key file as the Traefik provider doesn't support encrypted client key files. We are working to rectify this. In the meantime, please be careful where you store the unencrypted .key file.