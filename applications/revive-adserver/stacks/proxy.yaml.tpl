volumes:
%{ for volume in volumes ~}
  ${volume}:
    driver: local
    driver_opts:
      type: "nfs"
      o: "nfsvers=3,addr=${AZURE_STORAGE_ACCOUNT_HOST},nolock,soft,rw"
      device: ":/${AZURE_STORAGE_ACCOUNT}/${volume}"
%{ endfor ~}

services:
  proxy:
    image: traefik:v3.1.2
    command:
      - "--log.level=DEBUG"
      - "--accesslog=true"
      - "--api=true"
      - "--api.dashboard=true"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--providers.swarm=true"
      - "--providers.swarm.exposedByDefault=false"
      - "--providers.docker.endpoint=unix:///var/run/docker.sock"
      - "--entryPoints.ping.address=:8082"
      - "--entryPoints.traefik.address=:8080"
      - "--ping.entryPoint=ping"
      - "--certificatesResolvers.letsEncrypt.acme.email=mazharul@kahf.co"
      - "--certificatesResolvers.letsEncrypt.acme.storage=/traefik/tls/acme.json"
      - "--certificatesResolvers.letsEncrypt.acme.httpChallenge.entryPoint=web"
    volumes:
      - type: bind
        source: /var/run/docker.sock
        target: /var/run/docker.sock
        read_only: true
      - traefik:/traefik:rw
    ports:
      - target: 80
        published: 80
        mode: ingress
        protocol: tcp
      - protocol: tcp
        target: 443
        published: 443
        mode: ingress
      - protocol: tcp
        target: 8080
        published: 8080
        mode: ingress
      - protocol: tcp
        target: 8082
        published: 8082
        mode: ingress
    deploy:
      mode: global
      placement:
        constraints:
          - node.role==manager
        preferences:
          - spread: node.role.manager
      labels:
        - traefik.enable=true
        - traefik.http.services.proxy.loadbalancer.server.port=9999
        - traefik.http.routers.dashboard.entrypoints=traefik
        - traefik.http.routers.dashboard.rule=(PathPrefix(`/api`) || PathPrefix(`/dashboard`))
        - traefik.http.routers.dashboard.service=api@internal
    networks:
      - ${network_name}
networks:
  ${network_name}:
    external: true

