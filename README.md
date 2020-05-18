## - NGINX IN DEPTH (webserver, load balancer, reverse proxy, static-content, high performance, proxy)
sudo ln -s /etc/nginx/conf.d/wisdompetmed.local.conf /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/conf.d/wisdompetmed.local.conf /etc/nginx/sites-available

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

    guest_ip = "192.168.33.10"

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
    - unlink default
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
    $ scp -P 2201 -r site vagrant@127.0.0.1:/site
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
