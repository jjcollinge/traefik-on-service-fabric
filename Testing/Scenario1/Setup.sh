#Traefik install
sfctl application upload --path ./Traefik/ApplicationPackageRoot/
sfctl application provision --application-type-build-path ApplicationPackageRoot
sfctl application create --app-type TraefikType --app-version 1.0.0 --app-name fabric:/traefik


sfctl application upload --path ./Demos/apps/loadtest
sfctl application provision --application-type-build-path ./loadtest
for i in {30..300}
do
   ( echo "Deploying instance $i"
   sfctl application create --app-type NodeAppType --app-version 1.0.0 --parameters "{\"PORT\":\"90$i\"}" --app-name fabric:/node$i ) &
done