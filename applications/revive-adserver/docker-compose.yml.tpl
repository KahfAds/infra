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
    image: reviveadserver.azurecr.io/revive-adserver-${ENV}/backend:latest
    environment:
      DB_HOST: ${DB_HOST}
      DB_PORT: ${DB_PORT}
      DB_NAME: ${DB_NAME}
      DB_USERNAME: ${DB_USERNAME}
      DB_PASSWORD: ${DB_PASSWORD}
    volumes:
      - plugins:/app/plugins
      - admin-plugins:/app/www/admin/plugins
      - images:/app/www/images
      - var:/app/var
    deploy:
      placement:
        constraints:
          - node.role==manager
        preferences:
          - spread: node.role.manager

  admin:
    image: reviveadserver.azurecr.io/revive-adserver-${ENV}/web-admin:latest
    volumes:
      - plugins:/app/plugins
      - images:/app/www/images
    depends_on:
      - app
    deploy:
      labels:
        - traefik.enable=true
        - traefik.http.services.admin.loadbalancer.server.port=80
        - traefik.http.routers.app.entrypoints=web
        - traefik.http.routers.app.rule=Host(`52.230.5.115`)
      mode: replicated
      placement:
        constraints:
          - node.role==manager
        preferences:
          - spread: node.role.manager