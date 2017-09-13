# Running Traefik on Service Fabric

## How does it work?

Traefik is run in a Windows container. It uses it's ServiceFabric Provider to discover services, both statefull and stateless, and create a loadbalanced backends for each service. By default Health and Status are taken into account so traffic is only sent to healthy services ready to receive it. 

It then uses ApplicationParameters or Custom configuration to expose frontends which allow external traffic to reach the backends. 

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

Traefik has a nice set of features from [Rate limiting](https://docs.traefik.io/basics/#backends) to [Circuit breakers](https://docs.traefik.io/basics/#backends) at the backend and [Modifiers](https://docs.traefik.io/basics/#frontends) and [Matchers](https://docs.traefik.io/basics/#matchers) on frontends. 

These can all be used and customized, when deploying on Service Fabric, through the configuration template file. The template file is used to generate a TOML file configures Traefik. Here are some [examples of normal TOML files](https://docs.traefik.io/user-guide/examples/).

The template file is deployed and managed by SF using the inbuilt configuration mechanism. Users can update the file and then use the script /Traefik/Scripts/Update-Config.ps1 to have SF roll out this updated configuration to their cluster.

There is more detail on using the templates [here](Docs/CustomTemplates.MD) and [samples](Docs/SampleTemplates)


