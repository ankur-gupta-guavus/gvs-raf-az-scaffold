#!/bin/bash

USERID=$(echo -e "import hdinsight_common.Constants as Constants\nprint Constants.AMBARI_WATCHDOG_USERNAME" | python)
PASSWD=$(echo -e "import hdinsight_common.ClusterManifestParser as ClusterManifestParser\nimport hdinsight_common.Constants as Constants\nimport base64\nbase64pwd = ClusterManifestParser.parse_local_manifest().ambari_users.usersmap[Constants.AMBARI_WATCHDOG_USERNAME].password\nprint base64.b64decode(base64pwd)" | python)
CLUSTERNAME=$(echo -e "import hdinsight_common.ClusterManifestParser as ClusterManifestParser\nprint ClusterManifestParser.parse_local_manifest().deployment.cluster_name" | python)
HDP_VERSION=$(hdp-select  | grep spark2-client | awk '{print $NF}')

######## Code to download cdap deb packages ############

sudo curl -o /etc/apt/sources.list.d/cask.list http://repository.cask.co/ubuntu/precise/amd64/cdap/5.1/cask.list
curl -s http://repository.cask.co/ubuntu/precise/amd64/cdap/5.1/pubkey.gpg | sudo apt-key add -
sudo apt-get update

######## Code to install apache2 ###################

######## Code to get ansible scripts #####################

sudo mkdir -p /opt/guavus/
sudo apt-get -y  install git-core
sudo git clone https://github.com/ankur-gupta-guavus/gvs-raf-az-scaffold.git /opt/guavus/
sudo sh /opt/guavus/raf-hdi-cdap/ansible/bootstrap.sh

export USERID=$USERID
export PASSWD=$PASSWD
export CLUSTERNAME=$CLUSTERNAME
export HDP_VERSION=$HDP_VERSION

###################################################

########### Trigger ansible ######################

cd /opt/guavus/raf-hdi-cdap/ansible/; ansible-playbook -i inventory/reflex/hosts playbooks/cdap/deploy.yml --user $USERNAME --become --become-method sudo
