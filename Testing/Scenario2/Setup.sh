#Traefik install
sfctl application upload --path ./Traefik/ApplicationPackageRoot/
sfctl application provision --application-type-build-path ApplicationPackageRoot
sfctl application create --app-type TraefikType --app-version 1.0.0 --app-name fabric:/traefik

#Spin up some node apps
sfctl application upload --path ./Demos/apps/loadtest
sfctl application provision --application-type-build-path loadtest
for i in {100..120}
do
   ( echo "Deploying instance $i"
   sfctl application create --app-type NodeAppType --app-version 1.0.0 --parameters "{\"PORT\":\"25$i\", \"RESPONSE\":\"25$i\"}" --app-name fabric:/node25$i ) &
done


#Run load test
