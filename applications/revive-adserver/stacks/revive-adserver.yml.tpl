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
  app:
    image: kahfads${ENV}.azurecr.io/revive-adserver/backend:latest
    networks:
      - ${network_name}
    volumes:
      - plugins:/app/plugins
      - admin-plugins:/app/www/admin/plugins
      - images:/app/www/images
      - var:/app/var
    deploy:
      mode: replicated
      replicas: 4
      placement:
        preferences:
          - spread: node.availability.active

  maintenance:
    image: kahfads${ENV}.azurecr.io/revive-adserver/backend:latest
    volumes:
      - plugins:/app/plugins
      - admin-plugins:/app/www/admin/plugins
      - images:/app/www/images
      - var:/app/var
    command:
      - /opt/bitnami/php/bin/php
      - /app/scripts/maintenance/maintenance.php
      - admin.kahfads.com
    deploy:
      mode: replicated
      replicas: 0
      restart_policy:
        condition: none
      labels:
        - "swarm.cronjob.enable=true"
        - "swarm.cronjob.schedule=1 * * * *"
        - "swarm.cronjob.skip-running=true"

  admin:
    image: kahfads${ENV}.azurecr.io/revive-adserver/web-admin:latest
    volumes:
      - plugins:/app/plugins
      - images:/app/www/images
    networks:
      - ${network_name}
    depends_on:
      - app
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role==worker
        preferences:
          - spread: node.role.worker
      labels:
        - traefik.enable=true
        - traefik.http.routers.admin.entrypoints=websecure
        - traefik.http.routers.admin.rule=(PathPrefix(`/www/admin`) || Host(`admin.kahfads.com`))
        - traefik.http.routers.admin.tls=true
        - traefik.http.routers.admin.tls.certresolver=letsEncrypt
        - traefik.http.services.admin.loadbalancer.server.port=8080

  delivery:
    image: kahfads${ENV}.azurecr.io/revive-adserver/web-delivery:latest
    volumes:
      - images:/app/www/images
    networks:
      - ${network_name}
    depends_on:
      - app
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role==worker
        preferences:
          - spread: node.role.worker
      labels:
        - traefik.enable=true
        - traefik.http.routers.delivery.entrypoints=websecure
        - traefik.http.routers.delivery.rule=(PathPrefix(`/www/delivery`) || Host(`delivery.kahfads.com`))
        - traefik.http.routers.delivery.tls=true
        - traefik.http.routers.delivery.tls.certresolver=letsEncrypt
        - traefik.http.services.delivery.loadbalancer.server.port=8080

networks:
  ${network_name}:
    external: true