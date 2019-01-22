#!/bin/bash

generate_cdap_env() {
    echo -e "
export JAVA_HOME=\"/usr/lib/jvm/java-8-openjdk-amd64\"
if [ \"$JAVA_HOME\" != \"\" ]; then
  JAVA_HOME=$JAVA_HOME
else
  echo \"Error: JAVA_HOME is not set.\"
  exit 1
fi

JAVA=$JAVA_HOME/bin/java

export HADOOP_HOME_WARN_SUPPRESS=1

# Set native libs PATH
export JAVA_LIBRARY_PATH=${JAVA_LIBRARY_PATH}:/usr/hdp/2.6.5.0-292/hadoop/lib/native/Linux-amd64-64:/usr/hdp/2.6.5.0-292/hadoop/lib/native

export CDAP_HOME=/opt/cdap
export CDAP_CONF=/etc/cdap/conf
export LOG_DIR=/var/log/cdap
export PID_DIR=/var/run/cdap
export AUTH_JAVA_HEAPMAX=\"-Xmx1024m\"
export KAFKA_JAVA_HEAPMAX=\"-Xmx1024m\"
export MASTER_JAVA_HEAPMAX=\"-Xmx1024m\"
export ROUTER_JAVA_HEAPMAX=\"-Xmx1024m\"
export SPARK_HOME=\"/usr/hdp/current/spark2-client\"
export SPARK_MAJOR_VERSION=2

export OPTS=\"${OPTS} -Dhdp.version=${HDP_VERSION:-${HDP_VERSION}}\"

export TEZ_HOME=\"/usr/hdp/current/tez-client/\"
export TEZ_CONF_DIR=\"/etc/tez/conf\"
    " > /etc/cdap/conf/cdap-env.sh
}

generate_cdap_site() {
    echo -e "
<?xml version=\"1.0\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>

<configuration>
    <property>
      <name>root.namespace</name>
      <value>cdap</value>
    </property>
    <property>
      <name>hdfs.namespace</name>
      <value>/cdap</value>
    </property>
    <property>
      <name>hdfs.user</name>
      <value>yarn</value>
    </property>
    <property>
      <name>kafka.seed.brokers</name>
      <value>$(hostname):9092</value>
    </property>
    <property>
      <name>log.retention.duration.days</name>
      <value>7</value>
    </property>
    <property>
      <name>zookeeper.quorum</name>
      <value>${zkq}/cdap</value>
    </property>
    <property>
      <name>router.bind.address</name>
      <value>$(hostname)</value>
    </property>
    <property>
      <name>router.server.address</name>
      <value>$(hostname)</value>
    </property>
    <property>
      <name>app.program.jvm.opts</name>
      <value>-XX:MaxPermSize=128M \${twill.jvm.gc.opts} -Dhdp.version=${HDP_VERSION}</value>
    </property>
    <property>
      <name>dashboard.bind.port</name>
      <value>11011</value>
    </property>
    <property>
      <name>dataset.executor.container.memory.mb</name>
      <value>1536</value>
    </property>
    <property>
      <name>explore.enabled</name>
      <value>true</value>
    </property>
    <property>
      <name>explore.executor.container.memory.mb</name>
      <value>2304</value>
    </property>
    <property>
      <name>http.client.read.timeout.ms</name>
      <value>120000</value>
    </property>
    <property>
      <name>kafka.server.log.dirs</name>
      <value>/var/cdap/kafka-logs</value>
    </property>
    <property>
      <name>log.saver.container.memory.mb</name>
      <value>1536</value>
    </property>
    <property>
      <name>master.service.memory.mb</name>
      <value>1536</value>
    </property>
    <property>
      <name>metrics.memory.mb</name>
      <value>1536</value>
    </property>
    <property>
      <name>metrics.processor.memory.mb</name>
      <value>1536</value>
    </property>
    <property>
      <name>router.bind.port</name>
      <value>11015</value>
    </property>
    <property>
      <name>stream.container.memory.mb</name>
      <value>1536</value>
    </property>
    <property>
      <name>twill.java.reserved.memory.mb</name>
      <value>350</value>
    </property>
</configuration>
    " > /etc/cdap/conf/cdap-site.xml
}


download_cdap() {
    sudo curl -o /etc/apt/sources.list.d/cask.list http://repository.cask.co/ubuntu/precise/amd64/cdap/5.1/cask.list
    curl -s http://repository.cask.co/ubuntu/precise/amd64/cdap/5.1/pubkey.gpg | sudo apt-key add -
    sudo apt-get update
}


do_bootstrap() {
    [ $(getent group cdap) ] || sudo groupadd -g 503 cdap
    id -u cdap || sudo useradd -u 503 -g 503 cdap
    hdfs dfs -mkdir -p /user/yarn && hdfs dfs -chown yarn:yarn /user/yarn
    hdfs dfs -mkdir -p /user/cdap && hdfs dfs -chown cdap:cdap /user/cdap
    hdfs dfs -mkdir -p /cdap/tx.snapshot && hdfs dfs -chown -R yarn:hdfs /cdap
    test -d /var/log/cdap || ( sudo mkdir -p /var/log/cdap && sudo chown cdap:cdap /var/log/cdap )
    test -d /var/cdap/kafka-logs || ( sudo mkdir -p /var/cdap/kafka-logs && sudo chown cdap:cdap /var/cdap/kafka-logs )
    test -d /var/cdap/run || ( sudo mkdir -p /var/cdap/run && sudo chown cdap:cdap /var/cdap/run )
    dpkg-query -l cdap || zookeeper-client -server ${ZOOKEEPER_QUORUM} rmr /cdap
}

install_cdap() {
    sudo apt-get install -y cdap-gateway cdap-kafka cdap-master cdap-security cdap-ui
    sudo rm -f /etc/cdap/conf /opt/cdap/kafka/lib/log4j.log4j-1.2.14.jar
    sudo mkdir -p /etc/cdap/conf
    generate_cdap_env
    sudo chown -R cdap:hadoop /etc/cdap/conf
}


USERID=$(echo -e "import hdinsight_common.Constants as Constants\nprint Constants.AMBARI_WATCHDOG_USERNAME" | python)
PASSWD=$(echo -e "import hdinsight_common.ClusterManifestParser as ClusterManifestParser\nimport hdinsight_common.Constants as Constants\nimport base64\nbase64pwd = ClusterManifestParser.parse_local_manifest().ambari_users.usersmap[Constants.AMBARI_WATCHDOG_USERNAME].password\nprint base64.b64decode(base64pwd)" | python)
CLUSTERNAME=$(echo -e "import hdinsight_common.ClusterManifestParser as ClusterManifestParser\nprint ClusterManifestParser.parse_local_manifest().deployment.cluster_name" | python)
HDP_VERSION=$(hdp-select  | grep spark2-client | awk '{print $NF}')
ZOOKEEPER_QUORUM=$(cat /etc/hbase/conf/hbase-site.xml  | grep -A 1 hbase.zookeeper.quorum | grep value | sed 's/^.*<value>//;s/<\/value>.*$//;s/,/:2181,/g;s/$/:2181/')

download_cdap
do_bootstrap
install_cdap
