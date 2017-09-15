# Using Custom Templates for complex Traefik Configuration

## Introduction to Templating Language

Traefik leverages golang's built in [templating language](https://golang.org/pkg/text/template/). It may look scary, but don't be put off! It's relatively simple to get your head around and you don't need to know how to program in golang to use it.

A good resource to start with is the [Helm docs](https://docs.helm.sh/chart_template_guide/#template-functions-and-pipelines). Helm is an application package management system for [Kubernetes](https://kubernetes.io/) which also uses golang templating and their docs are great! 

## How to access cluster information in your template?

In the templates you have access to an `Object` with information about the services, application, partitions, instance and replicas available in your Service Fabric cluster. This can be accessed using the keyword `.Services`.

A simple example of this is `{{len .Services}}`. This will print the current number of services hosted in the Service Fabric cluster.

Child properties can be accessed using dot notation, for example (Tip: `Range` is roughly equivalent to a `foreach` loop in other languages):

```
{{range $service := .Services}}
    {{range $patitions := $service.Patitions}}
        {{ print $partition.ID $partition.ServiceKind}}
    {{end}}
{{end}}
```

This prints the `Parition.ID` and the `ServiceKind` (Stateful or Stateless) for each service in the cluster.
Skip to the full examples to see how this language can be used to build out a complete TOML configuration.

## ServiceFabric Helper Function

These are functions which can be used to make things easier when building your template. Mostly they operate on an object like a Service, Instance or Replica.

### Functions 

- `isPrimary`: Returns `true` if the Replica has a `ReplicaRole` of "Primary"
    - Takes a Replica (.Services[].Paritions[].Replicas)
    - Example: `{{ if isPrimary $replica}}`


- `isHealthy`: Returns `true` if the Replica/Instance has a `ReplicaStatus == Ready` and `HealthState != Error`
    - Takes a Replica or Instance (.Services[].Paritions[].Replicas or .Services[].Paritions[].Instances)
    - Example: `{{ if isHealthy $replica}}`


- `hasHTTPEndpoint`: Returns `true` if the Replica/Instance has an HTTP based endpoint defined in SF
    - Takes a Replica or Instance (.Services[].Paritions[].Replicas or .Services[].Paritions[].Instances)
    - Example: `{{ if hasHTTPEndpoint $replica}}`


- `getDefaultEndpoint`: Returns the `url` of the default endpoint for a Replica from it's `ServiceManifest`. If multiple endpoints exists, it picks the first one.
    - Takes a Replica or Instance (.Services[].Paritions[].Replicas or .Services[].Paritions[].Instances)
    - Example: `{{ print (getDefaultEndpoint $replica)}}`


- `getNamedEndpoint`: Returns the `url` of named endpoint for Replica
    - Takes a Replica or Instance (.Services[].Paritions[].Replicas or .Services[].Paritions[].Instances) and an endpoint name.
    - Example: `{{ print (getDefaultEndpoint $replica "NodeJsEndpoint")}}`


- `getApplicationParameter`: Returns the value of an Application Parameter from the `ApplicationManifest`
    - Takes an Application (.Services[].ApplicationData) and a Parameter Name
    - Example: `{{ if eq (getApplicationParameter $service.ApplicationData "SomeParamHere") "TheValueItCouldEqual" }}`


- `doesAppParamContain`: Returns `true` if the Application Parameter containers the specified string
    - Takes an Application (.Services[].ApplicationData), a Parameter Name and the string to search for in the parameter value
    - Example: Checks if "SomeAppParam" contains the service name `{{if doesAppParamContain $service.ApplicationData "SomeAppParam" $service.Name}}`


## Example 1: Manual Frontend Definition

In this example we're going to publish out several Service Fabric services to appear as a single API externally. 

This example assumes our cluster has the following deployed:

Application(s):

    - Shopping

Stateless Service(s):

    - Checkout (fabric:/Shopping/Checkout)
    - View (fabric:/Shopping/View)
    - Search (fabric:/Shopping/Search)

In our API exposed via Traefik we'll map the service addresses as follows:

Service Fabric name | External endpoint | Internal endpoint |
| --- | --- | --- |
| fabric:/Shopping/Checkout | http://{clusterfqdn}/basket | http://{hostipport}/ |
| fabric:/Shopping/View | http://{clusterfqdn}/shop | http://{hostipport}/shop


```

# While the Templating language is useful
# you can also manually define items using normal TOML 
# in the file. Below we manually define our frontends
# and mapping rules. Each fontend uses the fabric uri as the backend name
# for the service it's routing too. 

[frontends]
  [frontends.basket]
  # Here we define the backend which will serve the requests
  # using the fabric uri of the service
  backend = "fabric:/Shopping/Checkout"
    
    # Here we setup the routing rules
    # stripping they're path route to "/" on the backend
    [frontends.basket.routes.basket]
    rule = "PathPrefixStrip: /basket"

  [frontends.shop]
  backend = "fabric:/Shopping/View"

    # Here we setup the routing
    # we use Path to redirect to route '/shop' on backend
    [frontends.shop.routes.basket]
    rule = "Path: /shop"


# Automatically discover and add the backends
# 'range $ := .Services' creates a foreach loop, looping through each service in the cluster. 
[backends]{{range $service := .Services}}
    
    # The same 'range' loop is used for each Partition in each service. 
    {{range $partition := $service.Partitions}}

      # As we only want the stateless services from the cluster 
      # 'if eq' is used to check for stateless services. 
      {{if eq $partition.ServiceKind "Stateless"}}

        # Route more traffic to servers performing well
        [backends."{{$service.Name}}".LoadBalancer]
        method = "drr"

        # Remove servers with higher than 50% network error rate
        [backends."{{$service.Name}}".circuitbreaker]
        expression = "NetworkErrorRatio() > 0.5"

        # Here we combine 'range' and 'if' to add a server for 
        # each instance running the service in the cluster. Traefik will
        # balance load accross these instances. 
        {{range $instance := $partition.Instances}}
          
          # Here we use our first two helper functions from the Traefik SF provider
          # 'isHealthy' and 'hasHTTPEndpoint'. These take an Instance or Replica and 
          # return true if it's healthy or has and http endpoint respectively. 
          # A full list of the available functions linked to earlier in these docs. 
          {{if and (isHealthy $instance) (hasHTTPEndpoint $instance)}}
            
            [backends."{{$service.Name}}".servers."{{$instance.ID}}"]
            url = "{{getDefaultEndpoint $instance}}"
            weight = 1

          {{end}}
        {{end}}
      {{end}}
    {{end}}
{{end}}



```
