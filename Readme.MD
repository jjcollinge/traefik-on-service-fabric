# Running Traefik on Service Fabric

## How does it work?

Traefik is run in a Windows container and uses it's ServiceFabric Provider to discover services, both stateful and stateless, from the cluster. It then creates loadbalanced backends for each service. By default Health and Status are taken into account, so traffic is only sent to healthy services.

ApplicationParameters or Custom configuration are then used to expose these backends by creating frontends which allow external traffic to be routed. 

To learn more about the Traefik model of Frontends and Backends [see their documentation](https://docs.traefik.io/basics/). 

## Deployment

1. Clone this repository locally
2. Open Traefik.sln
3. Update the TOML file as appropriate in /ApplicationPackageRoot/TraefikPkg/Code/traefik.toml
    
    - Add certificates to Traefik to enable communications with SF
    - Generate the necessary files from PFX with the following command //todo: add command
    - Add the files to /ApplicationPackageRoot/TraefikPkg/Code/certs
    - Uncomment clientcertfilepath, clientkeyfilepath and cacertfilepath in the TOML file. Ensuring these point to the certificate file

4. Publish the project to your cluster
5. Set the clusters loadbalancer to forward the endpoint port set in your TOMl file. 

## Expose a service using Traefik: Simple

The simplest way to expose a service is using ApplicationParameters. 

Add a default parameter to your ApplicationPackageRoot/ApplicationManifest.xml as follows:

```
<Parameter Name="TraefikPublish" DefaultValue="" />
```

Under the ApplicationParameters/Local.5Node.xml (this name will vary depend on your deployment configuration) add the corresponding parameter with the services you which to publish listed as a comma separated list. For example:

```
 <Parameter Name="TraefikPublish" Value="fabric:/GettingStartedApplication/WebService" />
```

## Expose services using Traefik: Custom Configuration

Traefik has a nice set of features from [Rate limiting](https://docs.traefik.io/basics/#backends) to [Circuit breakers](https://docs.traefik.io/basics/#backends) at the backend also [Modifiers](https://docs.traefik.io/basics/#frontends) and [Matchers](https://docs.traefik.io/basics/#matchers) on frontends. 

These can all be used and customized, when deploying on Service Fabric, through the configuration template file. The template file is used to generate a TOML file which configures Traefik. Here are some [examples of normal TOML files](https://docs.traefik.io/user-guide/examples/).

The template file is deployed and managed by SF using configuration packages. Users can update the file and then use the script /Traefik/Scripts/Update-Config.ps1 to publish updates.

There is more detail on using the templates [here](Docs/CustomTemplates.MD) and [samples](Docs/SampleTemplates)


