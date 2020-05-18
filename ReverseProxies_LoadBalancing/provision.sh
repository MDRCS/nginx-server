# Update the package references
apt-get update

# Install nginx and supporting packages
apt-get install -y nginx

# Remove the default configuration
unlink /etc/nginx/sites-enabled/default

# Install the new configuration
cp /vagrant/upstreams.conf /etc/nginx/conf.d

# Start the app servers
/usr/bin/python3 /vagrant/start_app_servers.py &

# Load the configuration
systemctl reload nginx

