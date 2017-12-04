
sfctl application upload --path ./Demos/apps/loadtest
sfctl application provision --application-type-build-path loadtest
for i in {348..500}
do
   ( echo "Deploying instance $i"
   sfctl application create --app-type NodeAppType --app-version 1.0.0 --parameters "{\"PORT\":\"25$i\"}" --app-name fabric:/node25$i ) &
done