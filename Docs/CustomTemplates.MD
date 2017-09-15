# Custom Traefik Templates
In order to really harnass the power and flexibility of Traefik, you'll want to consider authoring your own custom TOML template file. Rather than defining which services should be exposed using an `ApplicationParameter` as you would for simple routing, you can customise the TOML template file `config.toml.tmpl` for much more complex configuration.

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

## Service Fabric Helper Function
We have provided a set of helper function which make it easier to access data about your Service Fabric cluster when building your own template. There functions mostly operate on an object like a Service, Instance or Replica.

### List of available functions

***

### `isPrimary`
**Inputs:**
- Replica (`.Services[].Partitions[].Replicas)

**Outputs:**
- Boolean

**Description:** 

Indicates whether a given `Replica` has a `ReplicaRole` of "Primary"

**Example:**

`{{ if isPrimary $replica}}`

***
### `isHealthy`
**Inputs:**
- Replica (`.Services[].Partitions[].Replicas)

**Outputs:**
- Boolean

**Description:** 

Indicates whether a given `Replica` has a `ReplicaStatus` of "Ready" and a `HealthState` not equal to "Error"

**Example:**

`{{ if isHealthy $replica}}`

***
### `hasHTTPEndpoint`
**Inputs:**
- Replica (`.Services[].Partitions[].Replicas`)
- OR Instance (`.Services[].Paritions[].Instances`)

**Outputs:**
- Boolean

**Description:** 

Indicates whether a given `Replica` or `Instance` has an available HTTP based endpoint defined in Service Fabric.

**Example:**

`{{ if hasHTTPEndpoint $replica}}`

***
### `getDefaultEndpoint`
**Inputs:**
- Replica (`.Services[].Partitions[].Replicas`)
- OR Instance (`.Services[].Paritions[].Instances`)

**Outputs:**
- String

**Description:** 

Selects the default endpoint URL for a `Replica` or `Instance`. If multiple endpoints exist for a given `Replica` or `Instance`, it will select the first.

**Example:**

`{{ print (getDefaultEndpoint $replica)}}`

***
### `getNamedEndpoint`
**Inputs:**
- Replica (`.Services[].Partitions[].Replicas`)
- OR Instance (`.Services[].Paritions[].Instances`)
- String

**Outputs:**
- String

**Description:** 

Selects a named endpoint URL for a `Replica` or `Instance`.

**Example:**

`{{ print (getNamedEndpoint $replica "NodeJsEndpoint")}}`

***
### `getApplicationParameter`
**Inputs:**
- Application (`.Services[].ApplicationData`)
- String

**Outputs:**
- String

**Description:** 

Attempts to find a parameter with the provided name in the `ApplicationManifest` and returns the associated value.

**Example:**

`{{ if eq (getApplicationParameter $service.ApplicationData "SomeParamHere") "TheValueItCouldEqual" }}`

***
### `doesAppParamContain`
**Inputs:**
- Application (`.Services[].ApplicationData`)
- String

**Outputs:**
- Boolean

**Description:** 

Attempts to find a parameter with the provided name in the `ApplicationManifest` and returns whether or not it exists.

**Example:**

`{{if doesAppParamContain $service.ApplicationData "SomeAppParam" $service.Name}}`

***

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
