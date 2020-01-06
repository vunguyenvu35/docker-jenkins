#!/bin/bash
systemctl stop nginx
sudo -H ./letsencrypt-auto certonly --standalone -d lptech.asia -d lptech.asia
systemctl start nginx

# Automatically Renew SSL Certificates (Optional)
crontab -e
# push
0 0 1 * * /opt/letsencrypt/letsencrypt-auto renew


#### update config file
# upstream lptech {
#         server 127.0.0.1:8080;
# }

# server {
#     listen   80;
#     server_name lptech.asia;
#     return 301 https://$host$request_uri;
# }

# server {
#     listen   443 ssl;
#     server_name lptech.asia;
#     ssl_certificate /etc/letsencrypt/live/lptech.asia/cert.pem;
#     ssl_certificate_key /etc/letsencrypt/live/lptech.asia/privkey.pem ;
#     ssl on;
#     ssl_session_cache builtin:1000 shared:SSL:10m;
#     ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
#     ssl_ciphers HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4;
#     ssl_prefer_server_ciphers on;

#     location / {
#          proxy_pass http://lptech;
#     }

#     location ~ /\.ht {
#         deny all;
#     }
# }

# 