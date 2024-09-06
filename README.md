# Mahfil Infra repo


## Important files
 * ```docker-compose.yml``` — get the api, web, and monitoring containers up and running locally. After running, you can access the api at http://localhost/api and the web at http://localhost.
 * ```api``` - api container. A sample python API.
 * ```www``` - web container. All static web files are in the \www\website folder. The Dockerfile here should compile the website into production ready optimized format to be served by nginx. 
 * ```nginx-app``` - nginx container. This is the nginx server that serves the web and api.
 * ```monitor``` - all monitoring container
   * ```promtail``` - promtail container. this run on web servers to ship web server health statistics and nginx logs. 
   * ```loki``` - loki container. this is the log aggregation server.
   * ```grafana``` - grafana container. this is the grafana server.
     * ```dashboards``` - default dashboards to start grafana with. 
     * ```datasources``` - default datasources to start grafana with. 
   * ```prometheus``` - prometheus container. this is the prometheus server.
   * ```nginx``` - nginx for monitoring. 
 * ```\azure\tofu\``` — terraform code to provision the azure infrastructure.
   * ```docker-compose.web.yml``` — docker compose file to run the web server in the azure vm. This has production ready configuration. Make sure the mount points map the production disks. 
   * ```docker-compose.monitor.yml``` — docker compose file to run the monitoring stack in the azure vm. This has production ready configuration. Make sure the mount points map the production disks.
   * ```build-push.sh``` - build and push web, api, monitoring containers to azure container registry.

## What is deployed?
  * A Load balancer with public IP
  * HTTP, HTTPS rules on Load Balancer to forward to web servers
  * A virtual network with 2 subnets - one for webservers and one for postgresql
  * N webservers with redis, api, web, nginx_exporter, promtail, node_exporter running on them. 
  * 1 monitoring server with prometheus, loki, grafana, and nginx running on them.
  * 1 PostgreSQL server in its own subnet 
  * Private DNS entry for PostgreSQL server.
  * After creation, all the servers are apt upgraded and rebooted to install the latest updates. 