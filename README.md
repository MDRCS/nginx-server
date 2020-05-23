## - NGINX IN DEPTH (webserver, load balancer, reverse proxy, static-content, high performance, proxy)

    ## Config folders
    /etc/nginx
    /etc/nginx/conf.d
    /etc/nginx/sites-available
    /etc/nginx/sites-enabled
    ## Config file
    /etc/nginx/nginx.conf
    ## nginx Log:
    /var/log/nginx
    ## http-Root:
    /var/wwww/html

### + Setup Vagrant Ubuntu VM :

    $ vagrant init bento/ubuntu-16.04

    + Vagrant file :

    guest_ip = "192.168.0.3"

    Vagrant.configure("2") do |config|

        config.vm.box = "bento/ubuntu-16.04"
        config.vm.network "private_network", ip: guest_ip

        puts "---------------------------------------"
        puts "Demo URL : http://#{guest_ip}"
        puts "---------------------------------------"

    end

    $ vagrant up
    $ vagrant ssh

    #sudo su -
    #apt update
    #apt -y upgrade
    #apt install -y nginx
    #systemctl status nginx

    + Mean directories of nginx:
        -> /etc/nginx/sites-available # conf file
        -> /var/www/html # where there are websites pages content
        -> /var/log/nginx #log files

    + NGINX commands :
    - systemctl start nginx
    - systemctl stop nginx
    - systemctl is-active nginx
    - systemctl reload nginx
    - nginx -t # check configuration if it correct or not. before reloading it

    + Configuration For website `wisdompetmed.local.conf` :
    #default configuration
    - cd /etc/nginx/sites-enabled/
    - ls -ltr
        default -> /etc/nginx/sites-available/default

    ## Remove the default configuration
    unlink /etc/nginx/sites-enabled/default

    - vi /etc/nginx/conf.d/wisdompetmed.local.conf

        server {
            listen 80 default_server;
            server_name wisdompetmed.local www.wisdompetmed.local;
            index index.html index.htm index.php;
            root /var/www/wisdompetmed.local;
        }

    - nginx -t
    - systemctl reload nginx
    - mkdir /var/www/wisdompetmed.local
    - echo "hello world" > /var/www/wisdompetmed.local/index.html
    - systemctl status nginx

    - curl localhost

    # Copy files from Host to Vagrant Ubuntu
    $ vagrant plugin install vagrant-scp
    $ vagrant ssh-config
    $ scp -P 2202 -r static-website vagrant@127.0.0.1:./static-website
    $ password: vagrant
    #you should not be sudo user. else exit

    $ sudo apt install unzip
    $ ls /var/www/wisdompetmed.local
    $ unzip -o Wisdom_Pet_Medicine_responsive_website_LYNDA_12773.zip -d /var/www/wisdompetmed.local
    $ cd /var/www/wisdompetmed.local

    #secure files and folders make them readonly for world and write by root:
    $ sudo find /var/www/wisdompetmed.local -type f -exec chmod 644 {} \; # to secure the files
    $ sudo find /var/www/wisdompetmed.local -type d -exec chmod 755 {} \; # to secure the folders
    $ ls -ltr # check

    $ vi /etc/nginx/conf.d/wisdompetmed.local.conf

    #add
     server {
        [.....]

        location / {
            # First attempt to serve request as file, then
            # as directory, then fall back to displaying a 404.
            try_files $uri $uri/ =404;
        }

        location /image {
            # Allow the contents of the /image folder to be listed
            autoindex on;
        }

        error_page 404 /404.html;
        location = /404.html {
            internal;
        }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
            internal;
        }

        location = /500 {
            # to test error 500 page
            fastcgi_pass unix:/this/will/fail;
        }

    }

    $ nginx -t
    $ systemctl reload nginx

    # now you can check the pages uri/images | uri/404 | uri/500

    #add logs files
    $ nginx -t
    $ systemctl reload nginx
    $ cd /var/log/nginx
    $ ls -ltr

    #requesting home page 10 times to valide logs
    $ for i in {1..10}; do curl localhost > /dev/null; done
    $ cat wisdompetmed.local.access.log

    $ for i in {1..10}; do curl localhost/images/ > /dev/null; done
    $ cat wisdompetmed.local.images.access.log

### - Troubleshooting nginx
    $ nginx -t # check config files are correct.
    $ sudo lsof -P -n -i :80 -i :443 | grep LISTEN # check port 80 for http and 443 for https are open.
    $ sudo netstat -plan | grep nginx # check processes that are listening.


### - NGINX WebserverSecurity :

    # best practices
    1- keep your OS and Software up-to-date to protect yourself from old vulnerabilities.
    2- restrict access where possible.
    3- use passwords to protect sensitive informations.
    4- use SSL to protect transmissions and identify your site.

    # limit access
    $ vi /etc/nginx/conf.d/wisdompetmed.local.conf
        location /images/ {
            deny all;
        }

    $ nginx -t
    $ systemctl reload nginx

    # you won't get the page.

    # update restricction

    location /images/ {
        allow 192.168.0.0/24;
        allow 10.0.0.0/8;
        deny all;
    }

    $ nginx -t
    $ systemctl reload nginx

    $ vagrant destroy name

### - Establish Authentification to access home page:

    ### Install apache-utils
    $ apt-get install -y apache2-utils

    ### Create a password file outside of root directory for securing locations

    $ htpasswd -b -c /etc/nginx/passwords admin #  -b -c for creating file
    $ chown www-data /etc/nginx/passwords # only be read by root and nginx user
    $ chmod 600 /etc/nginx/passwords

    $ ls -ltr /etc/nginx/passwords # check if permissions has been applied

    # if you want to change password of a user
    $ htpasswd -b -c /etc/nginx/passwords admin
    - deleting password
    - new password

    # add auth in the sectionyou want -> / or /images ..etc

    $ vi /etc/nginx/conf.d/wisdompetmed.local.conf

        location /images/ {
            # Allow the contents of the /image folder to be listed
            autoindex on;
            auth_basic "Authentication is required...";
            auth_basic_user_file /etc/nginx/passwords; # outside http-root for security reasons
            access_log /var/log/nginx/wisdompetmed.local.images.access.log;
            error_log /var/log/nginx/wisdompetmed.local.images.error.log;
            allow 192.168.0.0/24;
            allow 10.0.0.0/8;
            deny all;
        }

    $ nginx -t
    $ systemctl reload nginx


### - Configure HTTPS :

    # SSL vs TLS
    + SSL can be reversed and it's deprecated.
    + TLS is used for encrypting web traffic.

    $ apt install openssl
    $ openssl req -batch -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx.key -out /etc/ssl/certs/nginx.crt

    # req "request to openssl"
    # -batch "remove the prompts altogether"
    # -x509 "generete a x509 certificate"
    # -nodes "not use DES encryption method"
    # -days 365 "lenth of time this certificate is valid"
    #-newkey "to generate a new key"
    # rsa:2048 "use RSA encryption method 2048-bit key"
    # -keyout "path to store the key"
    # -out "path to the certificate tha openssl wil generate"

    $ ls -ltr /etc/ssl/certs/nginx.crt #check certificat

    $ vi /etc/nginx/conf.d/wisdompetmed.local.conf


        server {
            listen       443 ssl;
            server_name  localhost;

            ssl_certificate      /etc/ssl/certs/nginx.crt;
            ssl_certificate_key  /etc/ssl/private/nginx.key;

            ssl_session_cache    shared:SSL:1m;
            ssl_session_timeout  5m;

            ssl_ciphers  HIGH:!aNULL:!MD5;
            ssl_prefer_server_ciphers  on;

            location / {
                root   /etc/nginx/html/;
                index  index.html index.htm;
            }
           }

        }

    $ nginx -t
    $ systemctl reload nginx

### - Reverse Proxy & Load balancer :

    + Reverse proxy
    - middle man between client and server
    - could handle just one server
    - help implementing SSL, Logs, for web applications
    - compress data so that reduce latency of response.
    - cache data so it can reduce request to a server each time.

    + load balancer :
    - could do all reverse proxy functionnalities but with many servers.

    # Setup a Reverse Proxy

    $ unlink /etc/nginx/sites-enabled/default
    $ vim /etc/nginx/conf.d/upstream.conf

    $ nginx -t
    $ systemctl reload nginx

![](./static/loadbalancer.png)

    # Setup a Loadbalancer

    # RUN THESE COMMANDS ON YOUR LOCAL WORKSTATION
    # Start the virtual machine and log in
    vagrant up
    vagrant ssh

    # Nginx is installed for you in this lesson.
    # Proceed with the following steps to complete the configuration.

    # RUN THESE COMMANDS ON THE VIRTUAL MACHINE
    sudo su -

    # Remove the default configuration
    unlink /etc/nginx/sites-enabled/default

    # Create a the new configuration
    vim /etc/nginx/conf.d/upstream.conf

    # Add the following contents to /etc/nginx/conf.d/upstream.conf:
    upstream app_server_7001 {
        server 127.0.0.1:7001;
    }

    upstream roundrobin {
        # default is round robin
        server 127.0.0.1:7001;
        server 127.0.0.1:7002;
        server 127.0.0.1:7003;
    }

    upstream leastconn {
        # The server with the fewest connections will get traffic
        # if we have two servers one take 1 sec and other take 20sec we will go each time for 1 sec server.
        least_conn;
        server 127.0.0.1:7001;
        server 127.0.0.1:7002;
        server 127.0.0.1:7003;
    }

    upstream iphash {
        # Connections will stick to the same server
        ip_hash;
        server 127.0.0.1:7001;
        server 127.0.0.1:7002;
        server 127.0.0.1:7003;
    }

    upstream weighted {
        # More connections will be sent to the weighted server
        server 127.0.0.1:7001 weight=2;
        server 127.0.0.1:7002;
        server 127.0.0.1:7003;
    }

    server {
        listen 80;

        location /proxy {
            # Trailing slash is key!
            proxy_pass http://app_server_7001/;
        }

        location /roundrobin {
            proxy_pass http://roundrobin/;
        }

        location /leastconn {
            proxy_pass http://leastconn/;
        }

        location /iphash {
            proxy_pass http://iphash/;
        }

        location /weighted {
            proxy_pass http://weighted/;
        }
    }

    # Test and reload the configuration
        nginx -t
        systemctl reload nginx

    ## Test and reload the configuration
    nginx -t
    systemctl reload nginx

    ## cat start_app_servers.py
    ```
    #!/usr/bin/env python3
    '''Module: Starts three HTTP servers'''
    import os
    import time
    from http.server import BaseHTTPRequestHandler, HTTPServer
    from pprint import pprint

    hostName = "localhost"

    class MyServer(BaseHTTPRequestHandler):
        def do_GET(self):
            #print(self.server)
            #print(self.headers)
            self.send_response(200)
            self.send_header("Content-type", "text/html")
            self.end_headers()
            self.wfile.write(bytes("""
            <!DOCTYPE html>
            <html>
                <head>
                    <style> h1 {
                                font-size:100px;
                                text-align:center;
                                margin-left:auto;
                                margin-right:auto
                               }
                            p {
                                font-size:20px;
                                text-align:center;
                              }
                    </style>
                    <title>%s</title>
                </head>
            <body>""" % self.headers['Host'] , "utf-8"))
            self.wfile.write(bytes("<h1>{}</h1>".format(self.request.getsockname()[1]), "utf-8"))
            self.wfile.write(bytes("<h1>{}</h1>".format(time.strftime('%X')), "utf-8"))
            self.wfile.write(bytes("</body></html>", "utf-8"))

    def start_server(port):
        this_server = HTTPServer((hostName, port), MyServer)
        print(time.strftime('%X'), "App server started - http://%s:%s" % (hostName, port))

        try:
            this_server.serve_forever()
        except KeyboardInterrupt:
            pass

        this_server.server_close()
        print(time.strftime('%X'), "App server stopped - http://%s:%s" % (hostName, port))

    # list of the ports the servers will listen on
    PORTS = [7001, 7002, 7003]

    # list to hold the PIDs from the forked servers
    SERVERS = []

    # start a fork for each port
    for port in PORTS:
        pid = os.fork()

        if pid:
            SERVERS.append(pid)
        else:
            start_server(port)
            exit(0)

    # wait for the servers to finish, bailing out on CTRL+C
    for server in SERVERS:
        try:
            os.waitpid(server, 0)
        except KeyboardInterrupt:
            exit(0)

    ```
    ## Start the app servers
    /usr/bin/python3  start_app_servers.py &

    ## Open each proxy location in a browser:
        http://192.168.0.3/roundrobin
        http://192.168.0.3/leastconn
        http://192.168.0.3/iphash
        http://192.168.0.3/weighted

    # troubleshooting problem - Address already in use:
    $ ps -fA | grep python
    $ kill 81651

### - Improve performance
    + Enable HTTP/2

    HTTP/2 allows browsers to request files in parallel, greatly improving the speed of delivery.
    You’ll need HTTPS enabled. Edit your browser configuration file, adding http2 to the listen directive,
    then restart NGINX:
        server {
           listen 443 http2 default_server;
           listen [::]:443 http2 default_server;
           #... all other content
        }

    + Enable gzip compression

    gzip compression can greatly decrease the size of files during transmission (sometimes by over 80%).
    Add the following to your server block:
        server {
           #...previous content
           gzip on;
           gzip_types application/javascript image/* text/css;
           gunzip on;
        }

    This will ensure that javascript files, images, and CSS files are always compressed.

    Warning:
    A security vulnerability exists when you enable gzip compression in conjunction with HTTPS that allows
    attackers to decrypt data. For static websites that don’t serve users sensitive data, this is less of an issue,
    but for any site serving sensitive information you should disable compression for those resources.

    + Enable client-side caching
    Some files don’t ever change, or change rarely, so there’s no need to have users re-download the latest version.
    You can set cache control headers to provide hints to browsers to let them know what files they shouldn’t request again.

        server {
           #...after the location / block
           location ~* \.(jpg|jpeg|png|gif|ico)$ {
               expires 30d;
            }
            location ~* \.(css|js)$ {
               expires 7d;
            }
        }

    Examine how frequently your various file types change, and then set them to expire at appropriate times.
    If .css and .js files change regularly, you should set the expiration to be shorter. If image files like .jpg never
    change, you can set them to expire months from now.

    + Dynamically route subdomains to folders
    If you have subdomains, chances are you don’t want to have to route every subdomain to the right folder.
    It’s a maintenance pain. Instead, create a wildcard server block for it, routing to the folder that matches the name:

        server {
               server_name ~^(www\.)(?<subdomain>.+).jgefroh.com$ ;
               root /var/www/jgefroh.com/$subdomain;
        }
        server {
                server_name ~^(?<subdomain>.+).jgefroh.com$ ;
                root /var/www/jgefroh.com/$subdomain;
        }

    Restart nginx, and you’ll automatically route subdomains to the same-named subfolder.

### - CentOS Nginx :
    $ rpm -qa | grep nginx # check weather nginx exist in your machine
    $ rpm -qa | grep epel-release # check weather epel-realease exist in your machine
    $ yum install epel-release
    $ yum install nginx

    $ cd /etc/nginx
    $ systemctl start nginx

![](./static/nginx-architecture.png)

    $ ps -ef --forest | grep nginx
    # this command will help you figure out the master process and how many workers there are configured.

    # nginx.conf in depth
    $ vi nginx.conf

        user nginx;
        worker_processes auto; # option auto give you 2 workers by default

        -> worker_processes 4;
        $ nginx -t
        $ systemctl reload nginx
        $ ps -ef --forest | grep nginx
            -> now there is 4 workers.

        #this directive means that one worker handle 1024 request
        events {
            worker_connections 1024;
        }

    # you can create a file a put into instructions and import it to have an organized files
    $ include ...

    #html files served in the front of webserver
    # ls /usr/share/nginx/html

    NOTE
    + Every important file used by nginx server you will find it in nginx.conf file

    # Configure our own nginx webserver
    $ cd /etc/nginx/conf.d
    $ touch web.conf
        server {
           server_name example.com www.example.com;

           location / {
             root /var/www/example;
             index index.html;
           }
        }

    $ nginx -t
    $ systemctl reload nginx
    $ mkdir /var/www/example
    $ echo "this is my first nginx webserver." > index.html
    # allow nginx to read files in this folder
    # check workers user by running vi nginx.conf -> user www-data
    $ sudo chown -R www-data /var/www/example

# Config a Reverse Proxy :

![](./static/reverse-proxy-architecture.png)

    ```
        webserver ip 192.168.0.4
        reverse_proxy ip 192.168.0.5
    ```


    #create another vagrant ubuntu machine and setup softwares on it.
    vagrant up
    vagrant ssh


    $ cd /etc/nginx/conf.d
    $ vi web.conf
    # basic reverse_proxy example :

        server {
            server_name _;

            location / {
                  proxy_pass http://192.168.0.4;
            }
        }

    $ cd /etc/nginx/sites-available
    $ rm -rf default.conf
    $ cd /etc/nginx/sites-enabled
    $ unlink default
    $ nginx -t
    $ systemctl reload nginx

    client : browser
    reverse_proxy : http://192.168.0.5/ forward -> http://192.168.0.4

    #check logs
    $ cd /var/log/nginx
    $ tail -f access.log

### - Reverse Proxy - X-Real-IP problem :


![](./static/x-real-ip-solution.png)

    + the problem here is that requests handled by the server come from one ip
      is the the reverse proxy ip

![](./static/x-real-ip-problem.png)

    + The solution should be to allow requests from the real ip

    - Solution
    # go to reverse-proxy server
    $ cd /etc/nginx/conf.d

        server {
            server_name _;

            location / {
                  proxy_pass http://192.168.0.4;
            ->    proxy_set_header X-Real-IP $remote_addr;
            }
        }


    $ nginx -t
    $ systemctl reload nginx

    # go to webserver
    #check logs
    $ cd /var/log/nginx
    $ tail -f access.log

        192.168.0.1 - - [19/May/2020:07:13:47 +0000] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.138 Safari/537.36"
        # 192.168.0.1 is not the ip of reverse-proxy but it 's the real ip of the host.


### - Reverse Proxy - Proxy Host Header problem :

![](static/proxy-host-header.png)

    + the problem here is that the server want to get the hostname not just the resource requested.
    # one hostname
    -> Get index.html   X

    # multiple hostnames
    -> Get blog.mdrahali.com/index.html   -> "my name is Mohamed El RAhali"   V
    -> Get stack.mdrahali.com/index.html   -> "hello world"   V

    + if we have multiple hostname for multiple purpose, it's an obligation to forward hostname
      to help webserver figure out what to respond

    NB : if we have one hostname, its not important to config this feature.


    #go to webserver

    $ cd /var/www/example
    $ mkdir example.com
    $ mkdir example.net
    $ cd example.com
    $ echo "this is my first nginx webserver." > index.html
    $ cd ..
    $ cd example.net
    $ echo "hello world" > index.html

    $ cd /etc/nginx/conf.d
    $ vi web.conf

        server {
           server_name mdrahali.com;

           location / {
             root /var/www/example/mdrahali.com;
             index index.html;
           }
        }

        server {
           server_name mdrahali.net;

           location / {
             root /var/www/example/mdrahali.net;
             index index.html;
           }
        }


    $ nginx -t
    $ systemctl reload nginx


    $ cd /etc/nginx/conf.d
    $ vi web.conf

        server {
            server_name _;

            location / {
                  proxy_pass http://192.168.0.4;
            ->    proxy_set_header Host $host;
            }
        }

    $ sudo chown -R www-data /var/www/example
    $ sudo chown -R www-data mdrahali.com/
    $ sudo chown -R www-data mdrahali.net/

    $ nginx -t
    $ systemctl reload nginx

    $ For testing and accepting doing a "catch-all", you can use server_name _ .

    $ cd /etc
    $ vi hosts
    #add this
    $ 127.0.0.1 locahost www.mdrahali.com mdrahali.com www.mdrahali.net mdrahali.net

    $ curl mdrahali.com
    $ curl mdrahali.net

    $ cd /var/log/nginx
    $ tail -f access.log
    This directive is available as part of nginx commercial subscription.

### - Loadbalancer :

    + prerequisites - Vagrant VM:

        1- server-1 -> 192.168.0.6
        2- server-2 -> 192.168.0.4
        3- load-balancer -> 192.168.0.5

    1- server-1 -> 192.168.0.6
    $ cd /var/www/
    $ mkdir example
    $ cd example && echo "server 1" > index.html
    $ cd /etc/nginx/conf.d
    $ vi web.conf
        server {
           server_name _;

           location / {
             root /var/www/example/;
             index index.html;
           }
        }

    $ nginx -t
    $ systemctl reload nginx
    $ curl localhost
        -> server 1

    2- server-2 -> 192.168.0.4
    $ cd /var/www/
    $ mkdir example
    $ cd example && echo "server 2" > index.html
    $ cd /etc/nginx/conf.d
    $ vi web.conf
        server {
           server_name _;

           location / {
             root /var/www/example/;
             index index.html;
           }
        }

    $ nginx -t
    $ systemctl reload nginx
    $ curl localhost
        -> server 2

    3- load-balancer -> 192.168.0.5
    $ cd /etc/nginx/conf.d
    $ vi web.conf
        upstream backend {
            server 192.168.0.4;
            server 192.168.0.6;
            zone backend 64k;
        }

        server {
                server_name mdrahali.com;
                listen 80;
                location / {
                      proxy_pass http://backend;
                      #health_check interval=10 fails=3 passes=2;
               }
        }

    NOTE
    -> `health_check` directive is available as part of nginx commercial subscription.
    -> it ping servers each time with an interval to see if server is down/up.

    # load balancing method implemented here is Round Robin. each server sequentially.

    1- first scenario
    - imagine 2 servers are down, 1 server is up and worker 3 requesting each server to respond to a request
      he will mark server 1,2 as down and get respond from server 3 and serve the client.
      the same scenario will repeat with other workers because each worker has it's own memory

![](./static/worker_memory_problem.png)

    + this is why nginx have a mechanism to configure a shared-memory to optimize this process.
    -> zone backend 64k

![](./static/shared_memory_archiecture.png)

    ++ The zone directive defines a memory zone that is shared among worker processes
       and is used to store the configuration of the server group. This enables the worker
       processes to use the same set of counters to keep track of responses from the servers
       in the group. The zone directive also makes the group dynamically configurable.

       - 64k :
        Setting the Size for the Zone
        There are no exact settings due to quite different usage patterns. Each feature,
        such as sticky cookie/route/learn load balancing, health checks, or re-resolving
        will affect the zone size.

        - For example, the 256 Kb zone with the sticky_route session persistence method and a single health check can hold up to:

            128 servers (adding a single peer by specifying IP:port);
            88 servers (adding a single peer by specifying hostname:port, hostname resolves to single IP);
            12 servers (adding multiple peers by specifying hostname:port, hostname resolves to many IPs).


    # Testing :

    ## Open each proxy location in a browser:
        http://192.168.0.5/roundrobin
        http://192.168.0.5/leastconn
        http://192.168.0.5/iphash
        http://192.168.0.5/weighted

    ## also you can test in terminal
    $ curl mdrahali.com/roundrobin
    $ curl mdrahali.com/leastconn
    $ curl mdrahali.com/iphash
    $ curl mdrahali.com/weighted


### - Health monitoring - active & passive :

    + tip 1 -  i can mark a server as down by :
        upstream backend {
            server 192.168.0.4 down;
            server 192.168.0.6;
            zone backend 64k;
        }

    + tip 2 - passive monitoring :

         upstream backend {
            server 192.168.0.4 max_fails=3 fail_timeout=50;
            server 192.168.0.6;
            zone backend 64k;
        }

        # go to server 1
        $ systemctl stop nginx

        # go to load balancer
        # for i in {1..3}; do curl mdrahali.com

        # go to server 1
        $ systemctl start nginx

        # go to load balancer
        $ curl mdrahali.com
        # you will observe that load-balancer won't request server 1 because he considere it as down fro 50s.

    max_fails=number
    sets the number of unsuccessful attempts to communicate with the server that should happen
    in the duration set by the fail_timeout parameter to consider the server unavailable for a
    duration also set by the fail_timeout parameter. By default, the number of unsuccessful attempts is set to 1.

    fail_timeout=time
    sets
    the time during which the specified number of unsuccessful attempts to communicate with the server
    should happen to consider the server unavailable;
    and the period of time the server will be considered unavailable.
    By default, the parameter is set to 10 seconds.

    + for more options in load-balancers -> http://nginx.org/en/docs/http/ngx_http_upstream_module.html


    + tip 3 - active monitoring :

    + health_check directive:
    interval – How often (in seconds) NGINX Plus sends health check requests (default is 5 seconds)
    passes – Number of consecutive health checks the server must respond to to be considered healthy (default is 1)
    fails – Number of consecutive health checks the server must fail to respond to to be considered unhealthy (default is 1)

    server {
        listen       80;
        proxy_pass   backend;
        health_check interval=10 passes=2 fails=3;
    }


### - Cache Header Control :

    # go to webserver

    $ vagrant ssh-config
    $ vagrant ssh

    # go to a new tab ./nginx-server

    $ cd static
    $ scp -P 2201 -r loadbalancer.png vagrant@127.0.0.1:.

    # go to webserver

    $ sudo mv loadbalancer.png /var/www/example
    $ cd /var/www/example && echo "hello world" > demo.txt
    $ sudo su -
    $ cd /etc/nginx/conf.d/
    $ vi web.conf

        server {
           server_name _;

           location / {
             root /var/www/example/;
             index index.html;
           }

         location ~ \.(png) {
             root /var/www/example/;
             add_header Cache-Control max-age=120;
             # this header means that the server will cache the png files for 120 sec. and delete it.
           }

         location ~ \.(txt) {
             root /var/www/example/;
             expires -1;
             # expires -1 means don't cache this resource, there is others options : expires 48h; expires 1d; expires 2w; ..etc
           }
        }

    $ nginx -t
    $ systemctl reload nginx
    $ curl -I http://192.168.0.6/loadbalancer.png

        HTTP/1.1 200 OK
        Server: nginx/1.10.3 (Ubuntu)
        Date: Wed, 20 May 2020 03:57:19 GMT
        Content-Type: image/png
        Content-Length: 891061
        Last-Modified: Wed, 20 May 2020 03:42:33 GMT
        Connection: keep-alive
        ETag: "5ec4a729-d98b5"
        Cache-Control: max-age=120
        Accept-Ranges: bytes

    $ curl -I http://192.168.0.6/demo.txt
        HTTP/1.1 200 OK
        Server: nginx/1.10.3 (Ubuntu)
        Date: Wed, 20 May 2020 03:58:00 GMT
        Content-Type: text/plain
        Content-Length: 15
        Last-Modified: Wed, 20 May 2020 03:45:14 GMT
        Connection: keep-alive
        ETag: "5ec4a7ca-f"
        Expires: Wed, 20 May 2020 03:57:59 GMT
        Cache-Control: no-cache
        Accept-Ranges: bytes

        location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
            expires 2d;
            add_header Cache-Control "public, no-transform";
        }

### + Other Cache directive :

    - Cache-Control directives#
      The following is a list of the common directives used and configured when using the Cache-Control header.
      See HTTP/1.1 section 14.9 for a further explanation of the directives available.

        Cache-Control: no-cache#
        no-cache uses the ETag header to tell caches that this resource cannot be reused without first checking
        if the resource has changed on the origin server. This means that no-cache will make a trip back to
        the server to ensure the response has not changed and therefore is not required to download the
        resource if that is the case.

        Cache-Control: no-store#
        no-store is similar to no-cache in that the response cannot be cached and re-used, however there is
        one important difference. no-store requires the resource to be requested and downloaded from the
        origin server each time. This is an important feature when dealing with private information.

        Cache-Control: public#
        A response containing the public directive signifies that it is allowed to be cached by any
        intermediate cache. This however is usually not included in responses as other directives already
        signify if the response can be cached (e.g max-age).

        Cache-Control: private#
        The private directive signifies that the response can only be cached by the browser that is accessing the file.
        This disallows any intermediate caches to store the response.

        Cache-Control: max-age=<seconds>#
        This directive tells the browser or intermediary cache how long the response can be used from the time it was requested.
        A max-age of 3600 means that the response can be used for the next 60 minutes before it needs to fetch a new response from the origin server.

        Cache-Control: s-maxage=<seconds>#
        s-maxage is similar to the above mentioned max-age however the "s" stands for shared and is relevant only to CDNs or other intermediary caches.
        This directive overrides the max-age and expires header.

        Cache-Control: no-transform#
        Intermediate proxies sometimes change the format of your images and files in order to improve performance. The no-transform directive
        tells the intermediate proxies not to alter the format or your resources.


### - Connections persistence | Keep Alive :

![](./static/keep-alive.png)

    + The first parameter sets a timeout during which a keep-alive client connection will stay open on the server side.
      The zero value disables keep-alive client connections.

    # keepalive connection with resources in this directory / for 65 sec :
        location / {
             root /var/www/example/;
             index index.html;
             keepalive_timeout 65;
           }

    $ nginx -t
    $ systemctl reload nginx
    $ curl -I http://192.168.0.6/

        HTTP/1.1 200 OK
        Server: nginx/1.10.3 (Ubuntu)
        Date: Wed, 20 May 2020 04:21:56 GMT
        Content-Type: text/html
        Content-Length: 9
        Last-Modified: Tue, 19 May 2020 09:13:39 GMT
        Connection: keep-alive
        ETag: "5ec3a343-9"
        Accept-Ranges: bytes


### - Limit_Rate | download :

    # webserver 1 - 192.168.0.6
    $ webserver 2

    # webserver 2
    # download this resource from webserver
    + wget http://192.168.0.6/loadbalancer.png

        2020-05-20 04:36:56 (241 MB/s) - ‘loadbalancer.png’ saved [891061/891061]

    - download bandwidth 241 MB/s

    # webserver 1
    $ cd /etc/nginx/conf.d#

        location ~ \.(png) {
             root /var/www/example/;
             add_header Cache-Control max-age=120;
             limit_rate 50k;
           }

    $ nginx -t
    $ systemctl reload nginx

    # go to webserver 2
    + wget http://192.168.0.6/loadbalancer.png
        2020-05-20 04:46:26 (51.0 KB/s) - ‘loadbalancer.png’ saved [891061/891061]

    -> from 241 MB/s to 51.0 KB/s.

### - Limit_Conn :

    + Limiting the Request Rate
    Rate limiting can be used to prevent DDoS attacks, or prevent upstream servers from being overwhelmed by too many requests at the same time.
    The method is based on the leaky bucket algorithm: requests arrive at the bucket at various rates and leave the bucket at fixed rate.

    Before using rate limiting, you will need to configure global parameters of the “leaky bucket”:

    key - a parameter used to differentiate one client from another, generally a variable
    shared memory zone - the name and size of the zone that keeps states of these keys (the “leaky bucket”)
    rate - the request rate limit specified in requests per second (r/s) or requests per minute (r/m)
    (“leaky bucket draining”). Requests per minute are used to specify a rate less than one request per second.

    # webserver 1
    $ vi web.conf
        add this -> limit_conn_zone $binary_remote_addr zone=addr:10m;


    $ nginx -t
    $ systemctl reload nginx

    # go to server 2
    $ wget http://192.168.0.6/loadbalancer.png

    # go to server 3
    $ this service is temporarily unavailable.


### - GeoIP :
    + this technique is useful when you have for example DDOS attacks from one country/city you can block all ips of this country/city.


    # go to webserver
    # Setup GeoIP

    # downlaod GeoIP Country from :

    -> https://www.maxmind.com/en/accounts/312431/geoip/downloads
    $ scp -P 2201 -r GeoLite2-Country.tar.gz vagrant@127.0.0.1:.
    $ mkdir /etc/nginx/geoip
    $ sudo mv GeoLite2-Country.tar.gz /etc/nginx/geoip
    $ cd /etc/nginx/geoip
    $ tar -zxvf GeoLite2-Country.tar.gz
    $ mv GeoLite2-Country_20200519/ geoip_country/


    #Add a Hostname to the webserver :
    $ cd /etc
    $ vi hosts
        -> 127.0.0.1       localhost       mdrahali.com

    $ cd /etc/nginx/
    $ vi nginx.conf
    # add this line in http directive :
      -> geoip_country /usr/share/GeoIP/GeoIP.dat; # the country IP database
         map "$host:$geoip_country_code" $deny_by_country {
            ~^mdrahali.com:(?!MA) 1;
            default 0;
        }
    $systemctl restart nginx
    :MA for morocco if you want code for other countries check this website https://www.nirsoft.net/countryip/

    $ nginx -t
    $ systemctl reload nginx

    $ cd /etc/nginx/conf.d
    $ vi web.conf
        if ($deny_by_country) { return 403; }

    $ nginx -t
    $ systemctl reload nginx

    # Testing GeoIP blocking
    $ curl mdrahali.com
        <html>
            <head><title>403 Forbidden</title></head>
                <body bgcolor="white">
                    <center><h1>403 Forbidden</h1></center>
                <hr><center>nginx/1.10.3 (Ubuntu)</center>
            </body>
        </html>

    # Test on iP ADDRESSES :
    $ sudo apt-get install mmdb-bin
    $ apt-get install libmaxminddb-dev
    $ mmdblookup --file /etc/nginx/geoip/geoip_country/GeoLite2-Country.mmdb --ip 192.168.0.6

    https://dev.maxmind.com/geoip/legacy/codes/iso3166/


    # Other Example :
    $ vi nginx.conf
     #GeoIP
      geoip_country /usr/share/GeoIP/GeoIP.dat;
      map $geoip_country_code $allow_visit {
                default yes;
                MA no;
       }

    $ cd conf.d
    $ vi web.conf
        if ($allow_visit = no) {
                return 403;
           }

    + more example  -> https://docs.nginx.com/nginx/admin-guide/security-controls/controlling-access-by-geoip/


### - Logging :

    $ vi nginx.conf
    # add this two statements :

    ->  log_format master '$remote_addr - $remote_user [$time_local] '
                               '"$request" $status $body_bytes_sent '
                               '"$http_referer" "$http_user_agent" "$gzip_ratio"';

    # add just master to the path
    ->  access_log /var/log/nginx/access.log master;

    $ cd conf.d
    $ vi web.conf
    #add this -> access_log /var/log/nginx/example.log;

    $ systemctl reload nginx

    $ cd /var/log/nginx
    $ cat example.log
        127.0.0.1 - - [20/May/2020:07:19:16 +0000] "GET / HTTP/1.1" 200 9 "-" "curl/7.47.0"
        127.0.0.1 - - [20/May/2020:07:19:17 +0000] "GET / HTTP/1.1" 200 9 "-" "curl/7.47.0"
        127.0.0.1 - - [20/May/2020:07:19:18 +0000] "GET / HTTP/1.1" 200 9 "-" "curl/7.47.0"

### - Compression :

    + Compression is a great way to reduce the amount of packets to send to client requesting a resource
      Compression Algorithms could reduce data sent to users by 70% to it enhance speed alot.

    $ vi demo.txt
    $ ls -lh
    $ gzip -9 -c demo.txt > demo.gz
    $ ls -lh

        -rw-rw-r-- 1 vagrant vagrant 2.1K May 20 07:31 demo.gz
        -rw-rw-r-- 1 vagrant vagrant 5.3K May 20 07:31 demo.txt

    - 65% reducing size of data.

    #Add Compression to the server:
    $ vi nginx.conf
        gzip on;
        -> gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
        gzip_disable "msie6";

    $ systemctl reload nginx

    $ cd /var/www/example
    $ vi demo.txt
    #add alot of text

    $ curl mdrahali.com/demo.txt > c1.txt
    $ curl -H "Accept-Encoding: gzip" mdrahali.com/demo.txt > c2.txt
    $ ls -lh
    #check sizes of each file.

    # level of compression :

    $ vi nginx.conf
    # add -> gzip_comp_level 9;

    + The level of gzip compression simply determines how compressed the data is on a scale from 1-9,
      where 9 is the most compressed. The trade-off is that the most compressed data usually requires
      the most work to compress/decompress, so if you have it set fairly high on a high-volume website,
      you may feel its effect.

### - Hotlink protection in Nginx

    Hotlinked files can be a major cause for bandwidth leeching for some sites. Here’s how you can hotlink protect
    your images and other file types using a simple location directive in your Nginx configuration file :

    location ~ \.(jpe?g|png|gif)$ {
         valid_referers none blocked mysite.com *.mysite.com;
         if ($invalid_referer) {
            return   403;
        }
    }

    Use the pipe (“|”) to separate file extensions you want to hotlink protect.

    The valid_referers directive contains the list of site for whom hotlinking is allowed. Here is an explanation
    of the parameters for the valid_referers directive :

    none - Matches the requests with no Referrer header.
    blocked - Matches the requests with blocked Referrer header.
    *.mydomain.com - Matches all the sub domains of mydomain.com. Since v0.5.33, * wildcards can be used in the server names.

### - Nginx Firewall :

![](./static/modsecurity-waf-plug-in.png)

    + nginx -V check modules of nginx

    -> Setup NAXSI

    Step 1 — Install NGINX && NAXSI

    $ wget http://nginx.org/download/nginx-1.14.0.tar.gz
    $ wget https://github.com/nbs-system/naxsi/archive/0.56.tar.gz -O naxsi
    $ tar -xvf nginx-1.14.0.tar.gz
    $ tar -xvf naxsi
    $ cd nginx-1.14.0
    $ sudo apt-get update
    $ sudo apt-get install build-essential libpcre3-dev libssl-dev
    $ ./configure \
        --conf-path=/etc/nginx/nginx.conf \
        --add-module=../naxsi-0.56/naxsi_src/ \
        --error-log-path=/var/log/nginx/error.log \
        --http-client-body-temp-path=/var/lib/nginx/body \
        --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
        --http-log-path=/var/log/nginx/access.log \
        --http-proxy-temp-path=/var/lib/nginx/proxy \
        --lock-path=/var/lock/nginx.lock \
        --pid-path=/var/run/nginx.pid \
        --user=www-data \
        --group=www-data \
        --with-http_ssl_module \
        --without-mail_pop3_module \
        --without-mail_smtp_module \
        --without-mail_imap_module \
        --without-http_uwsgi_module \
        --without-http_scgi_module \
        --prefix=/usr

    $ make
    $ sudo make install

    Step 2 — Configuring NAXSI

    $ sudo cp ~/naxsi-0.56/naxsi_config/naxsi_core.rules /etc/nginx/
    $ sudo vi /etc/nginx/naxsi.rules
         SecRulesEnabled;
         DeniedUrl "/error.html";

         ## Check for all the rules
         CheckRule "$SQL >= 8" BLOCK;
         CheckRule "$RFI >= 8" BLOCK;
         CheckRule "$TRAVERSAL >= 4" BLOCK;
         CheckRule "$EVADE >= 4" BLOCK;
         CheckRule "$XSS >= 8" BLOCK;
    $ mkdir /usr/html/
    $ sudo vi /usr/html/error.html
        <html>
          <head>
            <title>Blocked By NAXSI</title>
          </head>
          <body>
            <div style="text-align: center">
              <h1>Malicious Request</h1>
              <hr>
              <p>This Request Has Been Blocked By NAXSI.</p>
            </div>
          </body>
        </html>
    $ sudo vi /etc/nginx/nginx.conf
        http {
            include       mime.types;
            -> include /etc/nginx/naxsi_core.rules;
            include /etc/nginx/conf.d/*.conf;
            include /etc/nginx/sites-enabled/*;

        location / {
        include /etc/nginx/naxsi.rules;
            root   html;
            index  index.html index.htm;
        }

    Step 3 — Creating the Startup Script for Nginx

    $ sudo vi /lib/systemd/system/nginx.service
        [Unit]
        Description=The NGINX HTTP and reverse proxy server
        After=syslog.target network.target remote-fs.target nss-lookup.target

        [Service]
        Type=forking
        PIDFile=/run/nginx.pid
        ExecStartPre=/usr/sbin/nginx -t
        ExecStart=/usr/sbin/nginx
        ExecReload=/usr/sbin/nginx -s reload
        ExecStop=/bin/kill -s QUIT $MAINPID
        PrivateTmp=true

        [Install]
        WantedBy=multi-user.target

    $ sudo mkdir -p /var/lib/nginx/body
    $ sudo systemctl start nginx

    Step 4 — Testing NAXSI
    $ curl 'http://192.168.0.4/?q="><script>alert(0)</script>'
    This URL includes the XSS script "><script>alert(0)</script> in the q parameter and should be rejected by the server.
    According to the NAXSI rules that you set up earlier, you will be redirected to the error.html file and receive the following response:

        <html>
           <head>
               <title>Blocked By NAXSI</title>
                  </head>
                  <body>
                    <div style="text-align: center">
                      <h1>Malicious Request</h1>
                      <hr>
                      <p>This Request Has Been Blocked By NAXSI.</p>
                    </div>
                  </body>
            </html>

    $ tail -f /var/log/nginx/error.log

    Next, try another URL request, this time with a malicious SQL Injection query.
    $ curl 'http://192.168.0.4/?q=1" or "1"="1"'

    # same response -> malicious request

    $ tail -f /var/log/nginx/error.log

### - Enabling FastCGI Caching on your VPS

    $ cd /etc/nginx/conf.d
    $ vi web.conf
    # add :
             fastcgi_cache_path /etc/nginx/cache levels=1:2 keys_zone=MYAPP:100m inactive=60m;
             fastcgi_cache_key "$scheme$request_method$host$request_uri";

            location / {
                [...]
                fastcgi_cache MYAPP;
                fastcgi_cache_valid 200 60m;
            }

    #display cache recursively
    $ ls -lR /etc/nginx/cache/


### - HTTP2

    + HTTP2 require SSL so you should configure HTTPS before configuring HTTP2.

    $ wget http://nginx.org/download/nginx-1.14.0.tar.gz
    $ tar -xvf nginx-1.14.0.tar.gz
    $ nginx -V

         --conf-path=/etc/nginx/nginx.conf --add-module=../naxsi-0.56/naxsi_src/ --error-log-path=/var/log/nginx/error.log
         --http-client-body-temp-path=/var/lib/nginx/body --http-fastcgi-temp-path=/var/lib/nginx/fastcgi
         --http-log-path=/var/log/nginx/access.log --http-proxy-temp-path=/var/lib/nginx/proxy
         --lock-path=/var/lock/nginx.lock --pid-path=/var/run/nginx.pid --user=www-data --group=www-data
         --with-http_ssl_module --without-mail_pop3_module --without-mail_smtp_module --without-mail_imap_module
         --without-http_uwsgi_module --without-http_scgi_module --prefix=/usr

    $ ./configure --help | grep http_v2

        --with-http_v2_module              enable ngx_http_v2_module

    $ ./configure --conf-path=/etc/nginx/nginx.conf     \
                  --add-module=../naxsi-0.56/naxsi_src/     \
                  --error-log-path=/var/log/nginx/error.log     \
                  --http-client-body-temp-path=/var/lib/nginx/body  \
                  --http-fastcgi-temp-path=/var/lib/nginx/fastcgi   \
                  --http-log-path=/var/log/nginx/access.log     \
                  --http-proxy-temp-path=/var/lib/nginx/proxy   \
                  --lock-path=/var/lock/nginx.lock  \
                  --pid-path=/var/run/nginx.pid     \
                  --user=www-data   \
                  --group=www-data  \
                  --with-http_ssl_module    \
                  --without-mail_pop3_module    \
                   --without-mail_smtp_module   \
                    --without-mail_imap_module  \
                    --without-http_uwsgi_module \
                     --without-http_scgi_module \
                      --prefix=/usr             \
                        --with-http_v2_module

    $ make
    $ make install
    $ systemctl restart nginx

    $ /etc/nginx#
    $ vi nginx.conf

    add -> listen 443 ssl `http2`;

    $ systemctl reload nginx

    $ curl -I -L https://192.168.0.4


### - HTTP2 | Server Push

    # basicaly here we configured http2 request that if client request /demo.html push other files

    $ vi nginx.conf

    location = /demo.html {
        http2_push /style.css;
        http2_push /image1.jpg;
        http2_push /image2.jpg;
    }

    $ apt-get install nghttp2-client
    $ nghttp -ans https://192.168.0.4/index.html

### DISABLE X-FRAME Clickjacking :
add_header X-XSS-Potection "1; mode=block";

    There are three settings for X-Frame-Options:

    SAMEORIGIN: This setting will allow the page to be displayed in a frame on the same origin as the page itself.
    DENY: This setting will prevent a page displaying in a frame or iframe.
    ALLOW-FROM URI: This setting will allow a page to be displayed only on the specified origin.

    # go to your local machine
    $ add_header X-Frame-Options sameorigin always;
    $ add_header X-Frame-Options deny;
    $ add_header X-Frame-Options "ALLOW-FROM http://www.domain.com

    # Disable ClickJacking

    # cd /etc/nginx/conf.d
    # vi web.conf
    # add add_header X-Frame-Options sameorigin always;

    # Test with this html file :

        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <title>Title</title>
        </head>
        <body>
            <iframe src="http://192.168.0.6/"
                    height="200" width="300"></iframe>
        </body>
        </html>
