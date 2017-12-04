Enable Application Insight Traefik Watchdog
================

1. Uncomment the following lines in `/Traefik/ApplicationPackageRoot/ApplicationManifest.xml`

``` xml
    <Service Name="Traefik" ServicePackageActivationMode="ExclusiveProcess">
      <StatelessService ServiceTypeName="TraefikType" InstanceCount="[Traefik_InstanceCount]">
        <SingletonPartition />
      </StatelessService>
    </Service>
    <!-- <Service Name="Watchdog" ServicePackageActivationMode="ExclusiveProcess">
      <StatelessService ServiceTypeName="WatchdogType" InstanceCount="[Traefik_InstanceCount]">
        <SingletonPartition />
      </StatelessService>
    </Service> -->
```

2. Copy your Application Insights instrumentation key in into the placeholder `__YOURKEYHERE__` in `/Treafik/ApplicationPackageRoot/Watchdog/ServiceManifest.xml`

``` xml
      <ExeHost>
        <Program>traefik-appinsights-watchdog.exe</Program>
        <Arguments>--appinsightskey=__YOURKEYHERE__ --watchdogtestserverport=29001 --pollintervalsec=60 --debug=true</Arguments>
        <WorkingFolder>CodePackage</WorkingFolder>
        <!-- Uncomment to log console output (both stdout and stderr) to one of the
             service's working directories. -->
        <!-- <ConsoleRedirection FileRetentionCount="5" FileMaxSizeInKb="2048" /> -->
      </ExeHost>
```

3. *Optional* Review, add or adjust any arguments for full details on the watchdog see it's [repository here](https://github.com/lawrencegripper/traefik-appinsights-watchdog)