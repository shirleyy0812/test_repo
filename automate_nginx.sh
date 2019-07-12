sudo apt-get update -y && apt-get upgrade -y
sudo apt-get install -y nginx
echo "Hello World from host" $HOSTNAME "!" | sudo tee -a /var/www/html/index.html
