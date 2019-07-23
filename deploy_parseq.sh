#!/usr/bin/env bash

# Summary: to install lid-runner dependencies and the app dependencies and link them properly with ECL. Then to start the application.
# To use: ARTIFACORY_URL='http://10.0.46.6:8000'; SCRIPT_NAME='lid-launcher-parseq-v1.sh'; bash <(curl -s $ARTIFACORY_URL/$SCRIPT_NAME)
set -e
#set -x
echo "Bootstrap lid-runner dependencies (py3.6) at ECL paths..."
yum install -y centos-release-scl
yum install -y rh-python36
yum install -y libxslt
#scl enable rh-python36 bash || true

mkdir -p /export/content/lid
mkdir -p /export/apps/python/3.6/bin
ln -sf /opt/rh/rh-python36/root/usr/bin/python /export/apps/python/3.6/bin/python3.6
ln -sf /opt/rh/rh-python36/root/usr/lib64/libpython3.6m.so.rh-python36-1.0 /usr/lib64/libpython3.6m.so.1.0
ln -sf /usr/lib64/libssl.so.10 /usr/lib64/libssl.so.1.0.0
ln -sf /usr/lib64/libcrypto.so.1.0.2k /usr/lib64/libcrypto.so.1.0.0

echo 'Add user/group of app'
groupadd app || echo "Group app already exists."
useradd -g app app || echo "User app already exists."
chown app /export/content/lid

echo "Install application dependencies..."
yum install -y graphviz
yum install -y hostname
yum install -y iproute
yum install -y which
yum install -y java-1.8.0-openjdk-devel

echo "Create symlink for JDK at ECL paths..."
mkdir -p /export/apps/jdk/JDK-1_8_0_121
cd /export/apps/jdk/; ln -sf /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.212.b04-0.el7_6.x86_64 JDK-1_8_0_212

echo "Download and install the temp lid-runner"
LID_RUNNER_TAR_NAME='lid-runner_linux_rhel7_x86_64-0.3.5.tar.gz'
wget http://10.0.46.6:8000/lid-runner_linux_rhel7_x86_64-0.3.5.tar.gz
tar vxf lid-runner_linux_rhel7_x86_64-0.3.5.tar.gz
echo "Lid-runner version is `cat ./etc/lid-runner/VERSION` on this host `hostname -f`."

echo "Running lid-runner with steps of downloading/installing the tarball"
./bin/lid-runner --debug execute -f dev -p '{"action": "deploy-product", "fabric": "dev", "name": "parseq-tracevis-server", "instance": "i001", "distribution": {"targets": ["app.azure.com"]}, "product": "parseq-tracevis-server", "application_instance": {"name": "parseq-tracevis-server", "instance": "i001", "product": "parseq-tracevis-server", "version": "0.0.7", "installation_id": "abcd", "kind": "generic"}, "steps": [{"action": "artifact.fetch", "args": {"url": "http://10.0.46.6:8000/parseq-tracevis-server-0.0.7.tgz", "filename": "/export/content/lid/dist/com.linkedin.parseq-tracevis-server/parseq-tracevis-server/0.0.7/parseq-tracevis-server-0.0.7.tgz"}}, {"action": "artifact.install", "args": {"source": "/export/content/lid/dist/com.linkedin.parseq-tracevis-server/parseq-tracevis-server/0.0.7/parseq-tracevis-server-0.0.7.tgz", "destination": "parseq-tracevis-server.tgz"}}, {"action": "generic.configure", "args": {"product_name": "parseq-tracevis-server", "application_name": "parseq-tracevis-server", "service_name": "parseq-tracevis-server", "version": "0.0.7", "ports": {"http": {"port": 8080, "protocol": "http"}}}}]}' --simulate-host app.azure.com


echo "Stopping the application"
/export/content/lid/apps/parseq-tracevis-server/abcd/bin/control stop || echo "The app has not been running."

echo 'Sleep 2 seconds..'
sleep 2

echo "Starting the application"
/export/content/lid/apps/parseq-tracevis-server/abcd/bin/control start

echo 'Sleep 5 seconds and validating application process is running'
sleep 5
ps -ef | grep parse[q]

echo "Validating app port is open"
curl -v http://localhost:8080 | grep Viewer

echo "Finished application deployment."
set +e
exit 0
