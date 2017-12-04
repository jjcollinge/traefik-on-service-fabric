echo "Cleaning up - may see errors if not prevously deployed"
sfctl application delete --application-id TraefikType
sfctl application unprovision --application-type-name TraefikType --application-type-version 1.0.4
sfctl store delete --content-path ApplicationPackageRoot

echo "Traefik install"
sfctl application upload --path ./Traefik/ApplicationPackageRoot/
sfctl application provision --application-type-build-path ApplicationPackageRoot
sfctl application create --app-type TraefikType --app-version 1.0.4 --app-name fabric:/TraefikType
