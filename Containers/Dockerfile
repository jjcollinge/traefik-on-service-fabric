FROM traefik:v1.5.1

COPY servicefabric.crt /servicefabric.crt
COPY servicefabric.key /servicefabric.key
COPY traefik.toml /

EXPOSE 8080
EXPOSE 80

ENTRYPOINT [ "/traefik", "--configfile=traefik.toml" ]