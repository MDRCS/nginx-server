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

# Start the app servers
    /usr/bin/python3 /vagrant/start_app_servers.py &

# Open each proxy location in a browser: 
    http://192.168.0.3/roundrobin
    http://192.168.0.3/leastconn
    http://192.168.0.3/iphash
    http://192.168.0.3/weighted

# Refresh each page several times

