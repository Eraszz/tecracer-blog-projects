#!/bin/bash

sudo yum update -y
sudo yum install httpd -y
sudo systemctl start httpd
sudo systemctl enable httpd

sudo chmod 777 /var/www/html

sudo tee /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
  <head>
    <title>Apache Web Server</title>
  </head>
  <body>
    <h1>Apache Web Server</h1>
    <p>This is a simple HTML web page.</p>
  </body>
</html>

EOF