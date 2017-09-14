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

If working against a local development cluster skip to step 5

3. Download or copy your clusters `.pfx` certificate file into the folder `traefik-on-service-fabric\Traefik\Scripts\`. If you have multiple certificates, this should be the one you wish Traefik to use to authenticate against your cluster's management endpoint. Ideally, this will be a `read-only` certificate.

4. Set your execution policy to unrestricted to allow the scripts to run
`Set-ExectuionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser`

5. Create a passphrase file with restricted permissions for the .Pfx passphrase

5. Run the `Create-Certs.ps1` script

`.\Create-Certs.ps1 -PfxCertFilePath <myclustercert.pfx> -PfxPassphraseFilePath <mypassphrase.txt>`

6. Copy your generated certificate to the folder Traefik expects to find them in `traefik-on-service-fabric\Traefik\ApplicationPackageRoot\TraefikPkg\Code\certs`

`cp .\certs\* ..\ApplicationPackageRoot\TraefikPkg\Code\certs`

7. Edit the `traefik-on-service-fabric\Traefik\ApplicationPackageRoot\TraefikPkg\Code\traefik.toml` configuration file to make sure the certificate names match, the `clustermanagementurl` is correct and the `[servicefabric] provider is uncommented

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

8. You now have a choice (Jikes!). See [simple configuration](#simple-configuration) or [advanced configuration](#advanced-configuration)

9. Once configured, you can simply publish Traefik from Visual Studio like any other Service Fabric service.

10. To be able to route traffic through the Traefik API and see the dashboard, you'll need to open up and map the relevant ports on the Azure Load Balancer. These ports default to 80 (API) and 8080 (Dashboard) and can be configured in the `traefik-on-service-fabric\Traefik\ApplicationPackageRoot\TraefikPkg\Code\traefik.toml` file and the TraefikPkg's `ServiceManifest.xml`.

11. Once the deployment is complete, you should be able to visit the Traefik dashboard at http[s]://[clusterfqdn]:8080.

![img](Docs/Images/traefikonsf.png)

12. Now that you have a Traefik instance up and running, you can simply update the config by changing either the `ApplicationParameters` or `...traefik.toml` and then running the `traefik-on-service-fabric\Traefik\Scripts\Update-Config.ps1`. This will patch your configuration files (`ApplicationManifest.xml` and `ServiceManifest.xml`), create a config-only Service Fabric application package and kick off a rolling update.

## How does it work?

Traefik is hosted as a Service Fabric Guest Executable. Traefik has a built in Service Fabric [provider](https://github.com/containous/traefik/tree/master/provider) which will query the Service Fabric management API to discover what services are currently being hosted in the cluster (referred to as `backends`). The provider then maps routing rules (known as `frontends`) across these `backends`. Traffic then flows in via `entrypoints` (http, https, etc.), the `frontends` are then applied to load balance and filter traffic to each `backend`. The provider will take into account the `Health` and `Status` of each of the services to ensure traffic is only routed to healthy service instances.

To learn more about the Traefik model of Frontends and Backends [see their documentation](https://docs.traefik.io/basics/).

## Simple Configuration

The simplest way to expose a service is using `ApplicationParameters`. 

Add a default parameter to your `ApplicationPackageRoot/ApplicationManifest.xml` as follows:

```
<Parameter Name="TraefikPublish" DefaultValue="" />
```

Under the `ApplicationParameters/Local.5Node.xml` (this name will vary depend on your deployment configuration) add the corresponding parameter with the services you which to publish listed as a comma separated list. For example:

```
 <Parameter Name="TraefikPublish" Value="fabric:/GettingStartedApplication/WebService" />
```

## Advanced Configuration

Traefik has a nice set of features, including [Rate limiting](https://docs.traefik.io/basics/#backends) and [Circuit breakers](https://docs.traefik.io/basics/#backends) for backends and [Modifiers](https://docs.traefik.io/basics/#frontends) and [Matchers](https://docs.traefik.io/basics/#matchers) for frontends.

These can all be used and customised when deploying on Service Fabric through a configuration template file. The template file is used to generate a TOML file which configures Traefik. Here are some [examples of normal TOML files](https://docs.traefik.io/user-guide/examples/).

The template file is deployed and managed by Service Fabric using configuration packages. Users can update their configuration file and then use the script `/Traefik/Scripts/Update-Config.ps1` to publish configuration-only updates.

There is more detail on using the templates [here](Docs/CustomTemplates.MD) and [samples](Docs/SampleTemplates)


