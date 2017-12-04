ENDPOINT_TO_TEST=$1

#Spin up some node apps
sfctl application upload --path ./Demos/apps/loadtest
sfctl application provision --application-type-build-path loadtest
for i in {100..120}
do
   ( echo "Deploying instance $i"
   sfctl application create --app-type NodeAppType --app-version 1.0.0 --parameters "{\"PORT\":\"25$i\", \"RESPONSE\":\"25$i\"}" --app-name fabric:/node25$i ) &
done

#Run load test
docker run --rm -it williamyeh/wrk -c 100 -t6 -d15m $ENDPOINT_TO_TEST
docker run --rm -it williamyeh/wrk -c 100 -t6 -d15m $ENDPOINT_TO_TEST/large
