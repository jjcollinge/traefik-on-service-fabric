FROM microsoft/nanoserver

# Download the Traefik binary
RUN powershell.exe -NoProfile -Command "\
New-item -Type Directory -Path C:/traefik/; \
Invoke-WebRequest https://github.com/containous/traefik/releases/download/v1.5.1/traefik_windows-amd64.exe \
-Outfile C:/traefik/traefik.exe;"

COPY servicefabric.crt C:/traefik/servicefabric.crt
COPY servicefabric.key C:/traefik/servicefabric.key

# 'clustermanagementurl' must point to your cluster's public IP
# or an SF endpoint that is accessible from inside the container.
COPY traefik.toml C:/traefik/traefik.toml

WORKDIR C:/traefik/

# expose Traefik and it's dashboard.
EXPOSE 80
EXPOSE 8080

# to persist files, configure volumes.
ENTRYPOINT ["traefik.exe", "--configfile=traefik.toml"]