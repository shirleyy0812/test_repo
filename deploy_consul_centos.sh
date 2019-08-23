sudo yum update -y && sudo yum upgrade -y
sudo yum install unzip -y
CONSUL_VERSION="1.5.0"
curl --silent --remote-name https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip
curl --silent --remote-name https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS
curl --silent --remote-name https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS.sig
unzip consul_${CONSUL_VERSION}_linux_amd64.zip
sudo chown root:root consul
sudo mv consul /usr/local/bin/
consul -autocomplete-install
complete -C /usr/local/bin/consul consul
sudo useradd --system --home /etc/consul.d --shell /bin/false consul
sudo mkdir --parents /opt/consul
sudo chown --recursive consul:consul /opt/consul
# systemd config
sudo touch /etc/systemd/system/consul.service
{
echo "[Unit]";
echo "Description="LPS consul test"";
echo "Documentation=https://www.consul.io/";
echo "Requires=network-online.target";
echo "After=network-online.target";
echo "ConditionFileNotEmpty=/etc/consul.d/consul_configuration.json";
echo "";
echo "[Service]";
echo "User=consul";
echo "Group=consul";
echo "ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/";
echo "ExecReload=/usr/local/bin/consul reload";
echo "KillMode=process";
echo "Restart=on-failure";
echo "LimitNOFILE=65536";
echo ""
echo "[Install]";
echo "WantedBy=multi-user.target";
} | sudo tee /etc/systemd/system/consul.service
# create consul configuration and set permission
sudo mkdir --parents /etc/consul.d
sudo touch /etc/consul.d/consul_configuration.json
sudo chown --recursive consul:consul /etc/consul.d
sudo chmod 640 /etc/consul.d/consul_configuration.json
IP=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`
{
echo '{';
echo '  "bootstrap_expect": 3,';
echo '  "non_voting_server": false,';
echo '  "server": true,';
echo '  "datacenter": "azure-east-us-dc1",';
echo '  "data_dir": "/opt/consul",';
echo '  "encrypt": "Luj2FZWwlt8475wD1WtwUQ==",';
echo '  "ui": false,';
echo '  "log_level": "DEBUG",';
echo '  "bind_addr": "0.0.0.0",';
echo '  "client_addr": "0.0.0.0",';
echo "  \"advertise_addr\": \"$IP\",";
echo "  \"retry_join\": [\"$IP\"],";
echo '  "rejoin_after_leave": true,';
echo '  "performance": {';
echo '    "raft_multiplier": 1';
echo '  },';
echo '  "ports": {';
echo '    "https": 8501';
echo '  }';
echo '}';
} | sudo tee /etc/consul.d/consul_configuration.json
sudo chown --recursive consul:consul /opt/consul
sudo chown --recursive consul:consul /etc/consul.d
sudo yum install epel-release -y
sudo yum install jq -y
sudo yum install nginx -y
