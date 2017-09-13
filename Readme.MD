# Running Traefik on Service Fabric

## How does it work?

[Traefik](https://traefik.io/) is run as a Service Fabric Guest Executable and uses a built-in [ServiceFabric Provider](https://github.com/containous/traefik/tree/master/provider) to discover both, Stateful and Stateless services running in the cluster. It  creates load balanced backends for each service in the cluster. By default these load balancers take the service's `Health` and `Status` into account to ensure traffic is only routed to healthy service instances.

`ApplicationParameters` or custom a configuration file can be used to configure how Traefik should route external traffic to your backend services.

To learn more about the Traefik model of Frontends and Backends [see their documentation](https://docs.traefik.io/basics/). 

## Deployment

1. Clone this repository to your local machine
2. Open Traefik.sln in Visual Studio
3. Update the TOML file `/ApplicationPackageRoot/TraefikPkg/Code/traefik.toml` to reflect your desired Traefik configuration
    
    - Generate the necessary certificate files (`.cert,.crt,.key`) from your existing `.pfx` certificate. [Guide here](https://gist.github.com/ericharth/8334664)
    - Add the certificate files to the directory `/ApplicationPackageRoot/TraefikPkg/Code/certs` i.e.
        - .../certs/cacert.cer
        - .../certs/mycert.crt
        - .../certs/mycert.key
    - Uncomment `clientcertfilepath`, `clientkeyfilepath` and `cacertfilepath` in the TOML file. Ensuring these point to the correct certificate files

4. Publish the project to your cluster normally
5. Set the cluster's external loadbalancer to forward the endpoint port set in your TOMl file (80, 8080). 

## Expose a service using Traefik: Simple

The simplest way to expose a service is using `ApplicationParameters`. 

Add a default parameter to your `ApplicationPackageRoot/ApplicationManifest.xml` as follows:

```
<Parameter Name="TraefikPublish" DefaultValue="" />
```

Under the `ApplicationParameters/Local.5Node.xml` (this name will vary depend on your deployment configuration) add the corresponding parameter with the services you which to publish listed as a comma separated list. For example:

```
 <Parameter Name="TraefikPublish" Value="fabric:/GettingStartedApplication/WebService" />
```

## Expose services using Traefik: Custom Configuration

Traefik has a nice set of features, including [Rate limiting](https://docs.traefik.io/basics/#backends) and [Circuit breakers](https://docs.traefik.io/basics/#backends) for backends and [Modifiers](https://docs.traefik.io/basics/#frontends) and [Matchers](https://docs.traefik.io/basics/#matchers) for frontends.

These can all be used and customised when deploying on Service Fabric through a configuration template file. The template file is used to generate a TOML file which configures Traefik. Here are some [examples of normal TOML files](https://docs.traefik.io/user-guide/examples/).

The template file is deployed and managed by Service Fabric using configuration packages. Users can update their configuration file and then use the script `/Traefik/Scripts/Update-Config.ps1` to publish configuration-only updates.

There is more detail on using the templates [here](Docs/CustomTemplates.MD) and [samples](Docs/SampleTemplates)


