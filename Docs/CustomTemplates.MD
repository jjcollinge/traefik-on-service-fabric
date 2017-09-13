# Using Custom Templates for complex Traefik Configuration

## Introduction to Templating Language

Traefik uses golangs [templating language](https://golang.org/pkg/text/template/) but don't be put off it's relatively simple to get your head around and you don't need to know how to program in golang. 

A good resource to start which is the [Helm docs](https://docs.helm.sh/chart_template_guide/#template-functions-and-pipelines), Helm is an app packaing system for Kubernetes which also uses golang templating and they're docs are great. 

## Example 1: Manual Frontend Definition

In this example we're going to define some custom routing rules for our frontend. This will still use the 