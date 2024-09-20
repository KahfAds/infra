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
      - public
    volumes:
      - plugins:/app/plugins
      - admin-plugins:/app/www/admin/plugins
      - images:/app/www/images
      - var:/app/var
    deploy:
      placement:
        constraints:
          - node.role==worker
        preferences:
          - spread: node.role.worker

  admin:
    image: kahfads${ENV}.azurecr.io/revive-adserver/web-admin:latest
    volumes:
      - plugins:/app/plugins
      - images:/app/www/images
    networks:
      - public
    depends_on:
      - app
    deploy:
      labels:
        - traefik.enable=true
        - traefik.http.routers.admin.rule=Host(`${SERVER_ADDR}`)
        - traefik.http.services.admin.loadbalancer.server.port=8080
      mode: replicated
      placement:
        constraints:
          - node.role==worker
        preferences:
          - spread: node.role.worker
networks:
  public:
    external: true