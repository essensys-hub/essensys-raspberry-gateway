{
  config,
  lib,
  pkgs,
  essensysNginxSrc ? ../essensys-nginx,
  ...
}:
let
  cfg = config.services.essensys;
  ngx = cfg.nginx;
  gw = cfg.gateway;

  nginxSrc = essensysNginxSrc;

  eth0Bind =
    if gw.enable && gw.bindStrict then
      if gw.eth0Address != null then gw.eth0Address else "127.0.0.1"
    else
      "127.0.0.1";

  eth1Bind = if gw.enable then gw.eth1Address else "0.0.0.0";

  gatewayHttpConfig =
    if gw.enable then
      ''
        # essensys-nginx gateway profile (derived from essensys-ansible default.conf.j2)
        server {
            listen ${eth0Bind}:80;
            server_name _;
            return 444;
        }

        server {
            listen ${eth1Bind}:80 default_server;
            server_name _;

            allow 127.0.0.1;
            allow 10.0.0.0/8;
            allow 172.16.0.0/12;
            allow 192.168.0.0/16;
            deny all;

            port_in_redirect off;
            root ${ngx.frontendRoot};
            index index.html index.htm;
            charset utf-8;

            access_log ${cfg.logDir}/nginx-access.log;
            error_log ${cfg.logDir}/nginx-error.log warn;

            gzip on;
            gzip_vary on;
            gzip_min_length 1024;
            gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json application/javascript;

            location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|map)$ {
                expires 1y;
                add_header Cache-Control "public, immutable";
                access_log off;
            }

            location ~* \.html$ {
                expires -1;
                add_header Cache-Control "no-cache, no-store, must-revalidate";
                add_header Pragma "no-cache";
            }

            location /api/ {
                client_body_buffer_size 64k;
                client_max_body_size 64k;
                proxy_pass http://127.0.0.1:${toString ngx.backendPort}/api/;
                proxy_http_version 1.1;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_buffering on;
                proxy_buffer_size 4k;
                proxy_buffers 8 4k;
                proxy_busy_buffers_size 8k;
                proxy_max_temp_file_size 0;
                gzip off;
                proxy_pass_header Content-Type;
                proxy_pass_header Content-Length;
                proxy_pass_header Connection;
                proxy_hide_header X-Powered-By;
                proxy_hide_header Server;
            }

            location /mcp/ {
                proxy_pass http://127.0.0.1:${toString ngx.mcpPort}/;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_http_version 1.1;
                proxy_set_header Connection "";
            }

            location /admin/ {
                proxy_pass http://127.0.0.1:${toString ngx.controlPlanePort}/;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
            }

            location / {
                try_files $uri $uri/ /index.html;
            }
        }
      ''
    else
      builtins.readFile "${nginxSrc}/conf.d/default.conf";
in
{
  options.services.essensys.nginx = {
    enable = lib.mkEnableOption "Essensys Nginx reverse proxy (armoire HTTP profile)";

    frontendRoot = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/essensys/frontend";
    };

    backendPort = lib.mkOption {
      type = lib.types.port;
      default = 7070;
    };

    mcpPort = lib.mkOption {
      type = lib.types.port;
      default = 8083;
    };

    controlPlanePort = lib.mkOption {
      type = lib.types.port;
      default = 9100;
    };
  };

  config = lib.mkIf (cfg.enable && ngx.enable) {
    services.nginx = {
      enable = true;
      recommendedProxySettings = lib.mkForce false;
      recommendedGzipSettings = lib.mkForce false;
      recommendedOptimisation = lib.mkForce false;
      recommendedTlsSettings = lib.mkForce false;
      appendHttpConfig = gatewayHttpConfig;
    };

    systemd.services.nginx.preStart = lib.mkAfter ''
      mkdir -p ${cfg.logDir}
      mkdir -p ${ngx.frontendRoot}
    '';
  };
}
