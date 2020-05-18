# NGINX
- Lynda - Learning NGINX (https://www.lynda.com/course-tutorials/Nginx-High-Performance-Servers/724790-2.html)
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
## Install NGINX
```bash
sudo apt install nginx -y
nginx -v 
# systemctl commands
systemctl status nginx
systemctl status nginx --no-pager
systemctl start nginx
systemctl stop nginx
systemctl is-active nginx
systemctl start nginx
systemctl is-active nginx
systemctl reload nginx
# nginx Commands
nginx -h
nginx -t
nginx -T
nginx -T | less
view /etc/nginx/nginx.conf
view /etc/nginx/sites-available/default
view /etc/nginx/sites-enabled/default
```

# Create a static site (wisdompetmed) using on conf.d
## Remove the default configuration
unlink /etc/nginx/sites-enabled/default
## Install the new configuration
nano  /etc/nginx/conf.d/wisdompetmed.local.conf
### wisdompetmed.local.conf
server {
    listen 80 default_server;
    root /var/www/wisdompetmed.local;
    server_name wisdompetmed.local www.wisdompetmed.local;
    index index.html index.htm index.php;
    access_log /var/log/nginx/wisdompetmed.local.access.log;
    error_log /var/log/nginx/wisdompetmed.local.error.log;

    location / {
        # First attempt to serve request as file, then
        # as directory, then fall back to displaying a 404.
        try_files $uri $uri/ =404;
    }

    location /images/ {
        # Allow the contents of the /image folder to be listed
        autoindex on;
	    access_log /var/log/nginx/wisdompetmed.local.images.access.log;
	    error_log /var/log/nginx/wisdompetmed.local.images.error.log;
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

## Install the demo site
```bash
mkdir /var/www/wisdompetmed.local
echo 'site coming soon' > /var/www/wisdompetmed.local/index.html
find /var/www/wisdompetmed.local -type f -exec chmod 644 {} \; # to secure the files
find /var/www/wisdompetmed.local -type d -exec chmod 755 {} \; # to secure the folders
```
## Load the configuration
systemctl reload nginx

# Troubleshooting
## teste the logs
for i in {1..10}; do curl localhost/ > /dev/null; done
for i in {1..10}; do curl localhost/images/ > /dev/null; done
tail -f /var/log/nginx/*.log
## test ports
sudo lsof -P n -i :80 -i :443 | grep LISTEN 
sudo netstat -plan | grep nginx

# Create a dinimic site (LEMP Stack) 

## Install nginx and supporting packages PHP
apt install -y nginx unzip php-fpm php-mysql
nginx -v
php --version
systemctl status php7.2-fpm
### Open /etc/nginx/conf.d/wisdompetmed.local.conf for editing:
    vim /etc/nginx/conf.d/wisdompetmed.local.conf

#### following contents and then save the file:
location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;        fastcgi_intercept_errors on;
}
### test and reload the configuration:
    nginx -t
    systemctl reload nginx
### Create a PHP info page in the root directory of the demo site:
vim /var/www/wisdompetmed.local/info.php

### Add the following contents to info.php:
    <?php phpinfo(); phpinfo(INFO_MODULES); ?>
#### info
```html
<html>
	<head>
		<title>PHP Info</title>
	</head>
	<body>
		<?php
			phpinfo(); // Show all information, defaults to INFO_ALL
			phpinfo(INFO_MODULES); // Show just the module information.
		?>
	</body>
</html>
```


### Test PHP the connection by Load the info.php page in a browser or via curl: http://192.168.0.3/info.php

## install and config BD
apt-get install -y mariadb-server mariadb-client
mysql --version
systemctl status mysqld.service --no-pager
systemctl status nginx mysqld php7.2-fpm | grep -E "(Loaded|Active)"
### Secure the installation by running the MySQL Secure Installation comand:
mysql_secure_installation
### Connect to the database as the root user with the mysql client.
mysql -u root -p
### After logging in, create a demo database and an admin user with these commands:
```sql
create database if not exists appointments;
create user if not exists 'admin';
grant all on appointments.* to 'admin'@'localhost' identified by 'admin';
exit
```
### Connect to the database as the admin user:
mysql -u admin -padmin
### View the database with a few SQL commands:
```sql
Show databases;
use appointments;
Show tables;
exit
```
### Insert the appointment data
mysql -u admin -padmin appointments < appointment_database.sql
#### appointment_database.sql
```sql
CREATE TABLE IF NOT EXISTS data (
    ID int NOT NULL AUTO_INCREMENT,
    `Pet_Name` VARCHAR(9) CHARACTER SET utf8,
    `Owner_Name` VARCHAR(17) CHARACTER SET utf8,
    `Animal_Type` VARCHAR(10) CHARACTER SET utf8,
    `Breed` VARCHAR(20) CHARACTER SET utf8,
    `Reason_for_appointment` VARCHAR(85) CHARACTER SET utf8,
    `Appointment_date` VARCHAR(19) CHARACTER SET utf8,
    `Filename` VARCHAR(22) CHARACTER SET utf8,
    `Pet_Description` VARCHAR(120) CHARACTER SET utf8,
    primary key (ID)
);
INSERT INTO data VALUES
    (default, 'Pepe','Reggie Tupp','Rabbit','Cinnamon rabbit','It''s time for this rabbit''s post spaying surgery checkup','11/28/2018 1:30 PM','Pepe-505301170.jpg','Six-month-old Pepe is very active and is always keeping his owners, and us, on our toes!'),
    (default, 'Rio','Philip Ransu','Dog','French bulldog','Rio is up for his next round of vaccinations','11/28/2018 10:15 AM','Rio-139983615.jpg','Rio, the 5-year-old bulldog, loves to play ball with his best dog friend, Rudy.'),
    (default, 'Scooter','Zachary Heilyn','Hedgehog','White-bellied','Scooter has been pawing at his ear and may have an ear infection','11/28/2018 2:45 PM','Scooter-587954386.jpg','You have to keep an eye on Scooter because he will climb walls to escape his habitat.'),
    (default, 'Nadalee','Krystle Valerija','Dog','Chihuahua','This dog is coming in for his monthly nail trim and grooming','11/28/2018 4:00 PM','Nadalee-601919350.jpg','Nadalee is a 7-year-old long hair Chihuahua with a very pleasant, laid back, temperament.'),
    (default, 'Scout','Nicolette Bardeau','Dog','Jack Russell terrier','This dog is coming in for his annual checkup and vaccinations','11/28/2018 9:00 AM','Scout-482669440.jpg','Scout suffers from separation anxiety from his owner but finds comfort in his crate with his favorite toy.'),
    (default, 'Zera','Austin Finnagan','Iguana','Cayman brac iguana','This iguana''s is showing signs of dementia associated with his old age','11/29/2018 1:15 PM','Zera-599775030.jpg','This iguana is on the endangered species list, and is thriving well in her owner’s home.'),
    (default, 'Oddball','Howie Cadell','Guinea pig','American guinea pig','Oddball has a hard lump on right front foot','11/29/2018 10:00 AM','Oddball-534210612.jpg','Oddball was the runt of his litter and has some breathing problems but is thriving well.'),
    (default, 'Millie','Freya Terray','Dog','Malamute','MIllie has exhibited signs of an upset stomach and is not eating regularly','11/29/2018 11:45 AM','Millie-586349302.jpg','Millie found her owner at a rescue shelter in 2014 and is supporting her new family by doing pet commercials.'),
    (default, 'Fluffy','Tracy Westbay','Cat','Domestic longhair','Fluffy has some matted hair that needs to be groomed','11/29/2018 2:30 PM','Fluffy-483561506.jpg','Fluffy is a very fluffy 3-year-old cat, who loves watching cat videos and trying to recreate them.'),
    (default, 'Chyna','Sandie Gobnet','Turtle','Terrapin','This turtle is coming in for a checkup and to be tested for Salmonella','11/29/2018 4:00 PM','Chyna-545429720.jpg','Chyna got her name because she’s a gentle 13-year-old turtle with a tough shell.'),
    (default, 'Wesley','Nathan Cayden','Dog','Mixed breed','This dog is returning for his next heartworm treatment visit','11/29/2018 8:30 AM','Wesley-122458883.jpg','At 8 years old there isn’t anything Wesley can’t do, he’s very healthy and full of energy!'),
    (default, 'Pax','Sarah Greer','Dog','Mixed breed','This senior dog has been sluggish and showing lethargic behavior','11/30/2018 10:15 AM','Pax-487576086.jpg','Pax is a senior dog and is suffering from arthritic conditions, but doing well for his age.'),
    (default, 'Squiggles','Madisyn Roope','Cat','Orange tabby cat','Squiggles is due for her annual checkup and vaccinations','11/30/2018 11:30 AM','Squiggles-72970152.jpg','Squiggles was a feral rescue that is now kept as an indoor/outdoor cat, but prefers to be outside.'),
    (default, 'Lucky','Lisa Choy-Wu','Cat','Tortoiseshell cat','This cat has tartar buildup and her owner would like his teeth cleaned','11/30/2018 2:30 PM','Lucky-519705168.jpg','One-year-old Lucky suffers from a rare heart condition, but has been able to live a relatively normal life.'),
    (default, 'Bailey','Leslie Richardson','Cat','Persian','This cat is suffering from hotspots and dermatitis','11/30/2018 3:45 PM','Bailey-523832647.jpg','Bailey is a 3-year-old female Persian cat that was adopted by her owner as a baby.'),
    (default, 'Kiko','Kathlyn Zlata','Cat','Tabby cat','Kiko has been exhibiting excessive thirst and weight loss for the past few weeks','11/30/2018 9:00 AM','Kiko-478801178.jpg','Kiko is a very shy 8-year-old cat that was found as a baby under a refrigerator by her mommy.'),
    (default, 'Felix','Francine Benet','Iguana','Green iguana','Felix''s mom is coming in to follow up on  lab work results','12/1/2018 1:00 PM','Felix-591830956.jpg','Felix is a sly little 6-year-old iguana that is always getting into trouble and keeps his mom on her toes.'),
    (default, 'Sami','Maggie Rickland','Dog','Dalmation','Sami has had some changes in his bathroom in habits','12/1/2018 10:00 AM','Sami-163271312.jpg','Sami is a very happy go lucky 1-year-old Dalmatian that loves to play.'),
    (default, 'Cosmo','Jennifer Dawson','Bird','Parrot','Cosmo''s mom would like us to check for arthritic conditions and do a routine checkup','12/1/2018 11:30 AM','Cosmo-481057312.jpg','Cosmo is possibly the happiest parrot that lived, and loves to sing Happy Birthday to anyone that will listen.'),
    (default, 'Casper','Dalania Devitto','Dog','Bichon frise','This dog is coming in for a nail trim and grooming','12/1/2018 3:15 PM','Casper-178870793.jpg','Four-year-old Casper was rescued from a breeder when he was 2, and his owner takes great care in giving him a good life.'),
    (default, 'Chip','Jason Hemlock','Fish','Cichild','This fish has a spotty white patch developing on his back ','12/1/2018 8:45 AM','Chip-519252509.jpg','Chip is a vivacious 5-year-old African Cichlid with a bit of a temper towards other fish.'),
    (default, 'Tibbs','Shad Cayden','Dog','Dachshund','Tibbs has had an ongoing rash and cold symptoms and we are going to run allergy tests','12/2/2018 1:30 PM','Tibbs-598156630.jpg','Tibbs suffers from a spinal condition that can cause immobilization and his owner has to watch his activity levels.'),
    (default, 'Stich','Dennis Nicholback','Dog','English pointer','Stich has been having some stomach issues and is due for his vaccinations','12/2/2018 10:15 AM','Stich-56385517.jpg','Four-year-old Stich was born with a birth defect that required surgery at 6 weeks of age.'),
    (default, 'Shadow','Audry Topsy','Cat','Bombay','This cat has a red swollen eye with a discharge','12/2/2018 3:00 PM','Shadow-591817094.jpg','Shadow is a 5-year-old cat that gains weight very easily and has to be kept on a special diet.'),
    (default, 'Nugget','Darla Branson','Hamster','Golden hamster','This little nugget has  a rash on his stomach area','12/2/2018 9:00 AM','Nugget-499158128.jpg','Nugget’s got his name because his owner’s daughter though he looked like a golden nugget when he was a baby.');

```
### Creating index.php
mkdir /var/www/wisdompetmed.local/appointments
cp index.php /var/www/wisdompetmed.local/appointments
chmod +r /var/www/wisdompetmed.local/appointments/index.php
####  index.php
```html
<!DOCTYPE html>
<html>
<head>
    <title>Appointments</title>
    <style type="text/css">
		body {
			font-size: 15px;
			color: #343d44;
			font-family: "segoe-ui", "open-sans", tahoma, arial;
			padding: 0;
			margin: 0;
		}
		table {
			margin: auto;
			font-family: "Lucida Sans Unicode", "Lucida Grande", "Segoe Ui";
			font-size: 12px;
		}

		h1 {
			margin: 25px auto 0;
			text-align: center;
			text-transform: uppercase;
			font-size: 17px;
		}

		table td {
			transition: all .5s;
		}

		/* Table */
		.data-table {
			border-collapse: collapse;
			font-size: 14px;
			min-width: 537px;
		}

		.data-table th,
		.data-table td {
			border: 1px solid #e1edff;
			padding: 7px 17px;
		}
		.data-table caption {
			margin: 7px;
		}

		/* Table Header */
		.data-table thead th {
			background-color: #508abb;
			color: #FFFFFF;
			border-color: #6ea1cc !important;
			text-transform: uppercase;
		}

		/* Table Body */
		.data-table tbody td {
			color: #353535;
		}
		.data-table tbody td {
			text-align: left;
		}

		.data-table tbody tr:nth-child(odd) td {
			background-color: #f4fbff;
		}
		.data-table tbody tr:hover td {
			background-color: #ffffa2;
			border-color: #ffff0f;
		}

		/* Table Footer */
		.data-table tfoot th {
			background-color: #e5f5ff;
			text-align: left;
		}
		.data-table tfoot th:first-child {
			text-align: left;
		}
		.data-table tbody td:empty
		{
			background-color: #ffcccc;
		}
	</style>
</head>
<body>
    <h1>Wisdom Pet Medicine Appointments</h1>
    <?php
        echo "<p align='center'>Today is " . date("m/d/Y") . "</p>";
    ?>
    <table class="data-table">
        <tr>
            <th>Pet Name</th>
            <th>Owner Name</th>
            <th>Appointment Date</th>
            <th>Reason for Appointment</th>
        </tr>
        <?php
            $conn = mysqli_connect('localhost', 'admin', 'admin', 'appointments');
            if (!$conn) {
                die ('Failed to connect to MySQL: ' . mysqli_connect_error());
            }

            $result = mysqli_query($conn, 'SELECT * FROM data');

            if (!$result) {
                die ('SQL Error: ' . mysqli_error($conn));
            }

            if ($result->num_rows > 0) {
                while ($row = $result->fetch_assoc()) {
                    echo "<tr><td>". $row["Pet_Name"] ."</td><td>". $row["Owner_Name"] ."</td><td>". $row["Appointment_date"] ."</td><td>". $row["Reason_for_appointment"] ."</td></tr>";
                }
            }
        ?>
    </table>
</body>
</html>
```

### create the location for index.php
nano  /etc/nginx/conf.d/wisdompetmed.local.conf
#### secure location
```bash
location /appointments/ {
    # only allow IPs from the same network the server is on
    allow 127.0.0.0/24;
    allow 192.168.0.0/24;
    allow 10.0.0.0/8;
    deny all;
    access_log /var/log/nginx/wisdompetmed.local.appointments.access.log;
    error_log /var/log/nginx/wisdompetmed.local.appointments.error.log;
}
```
#### config deny page for the site 

```bash
location /deny {
    deny all;
}
```
#### Test and reload the configuration
nginx -t
systemctl reload nginx
### Make and customize the 403 page:
cp /var/www/wisdompetmed.local/404.html /var/www/wisdompetmed.local/403.html
nano /var/www/wisdompetmed.local/403.html # Modify the 403 page to use the correct wording for a 403 error.  Something like "We can't show you this" instead of "We can't find it."
#### config deny page for the site 
nano /etc/nginx/conf.d/wisdompetmed.local.conf
```bash
error_page 403 /403.html;
location = /403.html {
    internal;
    }
location /deny {
    deny all;
}
```
### Test and reload the configuration
    nginx -t
    systemctl reload nginx
#

## Add ssl to the site 

### Install apache-utils
apt-get install -y apache2-utils

### Create a password file outside of root directory for securing locations
```bash
htpasswd -b -c /etc/nginx/passwords admin admin #  -b -c for creating file
chown www-data /etc/nginx/passwords # only be read by root and nginx user
chmod 600 /etc/nginx/passwords 
```
### Add authentication to appointments
nano /etc/nginx/conf.d/wisdompetmed.local.conf
```bash
location /appointments/ {
    # only allow IPs from the same network the server is on
    allow 192.168.0.0/24;
    allow 10.0.0.0/8;
    deny all;
    auth_basic "Authentication is required...";
    auth_basic_user_file /etc/nginx/passwords; # outside http-root for security reasons
    # php  were is important to nginx to now how to handle php files in this location 
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
        fastcgi_intercept_errors on;
    }
}
```
### Test and reload the configuration
    nginx -t
    systemctl reload nginx

### Make and customize the 401 page:
cp /var/www/wisdompetmed.local/404.html /var/www/wisdompetmed.local/401.html
vim /var/www/wisdompetmed.local/401.html # Modify the 401 page to Authentication Required
#### config deny page for the site 
nano /etc/nginx/conf.d/wisdompetmed.local.conf
```bash
error_page 401 /401.html;
    location = /401.html {
        internal;
}
```
### Test and reload the configuration
    nginx -t
    systemctl reload nginx


# Install openssl if its not installed
which openssl
apt -y install openssl

## Create an SSL key and certificate
```bash
openssl req -batch -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx.key -out /etc/ssl/certs/nginx.crt 2>/dev/null
# req "request to openssl"
# -batch "remove the prompts altogether"
# -x509 "generete a x509 certificate"
# -nodes "not use DES encryption method" 
# -days 365 "lenth of time this certificate is valid"
#-newkey "to generate a new key"
# rsa:2048 "use RSA encryption method 2048-bit key"
# -keyout "path to store the key"
# -out "path to the certificate tha openssl wil generate"
```
### Add authentication to appointments
nano /etc/nginx/conf.d/wisdompetmed.local.conf
```bash
    server {
        listen 80 default_server;
        return 301 https://$server_addr$request_uri;
    }

    server {
        listen 443 ssl default_server;
        ssl_certificate /etc/ssl/certs/nginx.crt;
        ssl_certificate_key /etc/ssl/private/nginx.key;

        root /var/www/wisdompetmed.local;

```
### Test and reload the configuration
nginx -t
systemctl reload nginx
## cat /etc/nginx/conf.d/wisdompetmed.local.conf
```bash
server {
    listen 80 default_server;
    return 301 https://$server_addr$request_uri;
}

server {
    listen 443 ssl default_server;
    ssl_certificate /etc/ssl/certs/nginx.crt;
    ssl_certificate_key /etc/ssl/private/nginx.key;
    
    root /var/www/wisdompetmed.local;

    server_name wisdompetmed.local www.wisdompetmed.local;

    index index.html index.htm index.php;

    access_log /var/log/nginx/wisdompetmed.local.access.log;
    error_log /var/log/nginx/wisdompetmed.local.error.log;

    location / {
        # First attempt to serve request as file, then
        # as directory, then fall back to displaying a 404.
        try_files $uri $uri/ =404;
    }

    location /appointments/ {
        auth_basic "Authentication is required...";
        # outside http-root for security reasons
        auth_basic_user_file /etc/nginx/passwords;
        
        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
            fastcgi_intercept_errors on;
        }

        # only allow IPs from the same network the server is on
        allow 127.0.0.0/24;
        allow 192.168.0.0/24;
        allow 10.0.0.0/8;
        deny all;
        access_log /var/log/nginx/wisdompetmed.local.appointments.access.log;
        error_log /var/log/nginx/wisdompetmed.local.appointments.error.log;
    }

    location /images/ {
        # Allow the contents of the /image folder to be listed
        autoindex on;
        access_log /var/log/nginx/wisdompetmed.local.images.access.log;
        error_log /var/log/nginx/wisdompetmed.local.images.error.log;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
        fastcgi_intercept_errors on;
    }

    error_page 404 /404.html;
    location = /404.html {
        internal;
    }
    error_page 403 /403.html;
    location = /403.html {
        internal;
    }

    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        internal;
    }

    location /deny {
        deny all;
    }
    
    location = /500 {
        fastcgi_pass unix:/this/will/fail;
    }
}
```
# Reverse Proxies and Load Balancing
## Remove the default configuration
    unlink /etc/nginx/sites-enabled/default

## Create a the new configuration
    vim /etc/nginx/conf.d/upstream.conf

## Add the following contents to /etc/nginx/conf.d/upstream.conf:
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

## Refresh each page several times

