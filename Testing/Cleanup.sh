sfctl application list --query items[].id -o tsv | grep node | xargs -n 1 -P 12 sfctl application delete --application-id
sfctl application unprovision --application-type-name NodeAppType --application-type-version 1.0.0
sfctl store delete --content-path loadtest

sfctl application delete --application-id traefik
sfctl application unprovision --application-type-name TraefikType --application-type-version 1.0.4
sfctl store delete --content-path ApplicationPackageRoot