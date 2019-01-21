# Deploy an HDInsight cluster using existing default storage account

<a href="https://azuredeploy.net/" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

This template facilitates creation of Guavus RAF CDAP cluster within an Azure Subscription. As part of CDAP cluster an HDInsight cluster is also created as its a dependancy for CDAP to run.

## REQUIRED INPUT:

For deploying Guavus RAF CDAP, following inputs have to be provided:

1. clusterName - Name of CDAP cluster
2. clusterLoginPassword - 'admin' user Password to access Ambari/CDAP 
3. sshUserName - Username to access cluster via ssh (should be different from 'root' or 'admin')
4. sshPassword - Password for user defined above.
5. defaultStorageAccountName - The short name of the default Azure storage account name. This account needs to be secure transfer enabled.
6. defaultStorageAccountKey - The key of the default storage account.
7. defaultContainerName - The name of an existing/new Azure blob storage container.
8. workerNodeSize - Choose size of worker Nodes. Options Include:
	    - Standard_D3_v2 (4vCPU, 14GiB) 
        - Standard_D4_v2 (8vCPU, 28GiB)
        - Standard_D5_v2 (16vCPU, 56GiB)
9. workerCount - Number of worker nodes for Yarn queue.
10. vnetName - Name of virtual Network within the chosen Resource Group.
11. subnetName - Name of subnet in above virtual Network.

## RESOURCES ACCESS:
Post creation of RAF CDAP , resources can be accessed as following:

1. Ambari - `https://<clustername>.azurehdinsight.net/`
2. CDAP - `https://<clustername>-cdp.azurehdinsight.net/`

Credentials for both - `admin/<clusterLoginPassword>`
