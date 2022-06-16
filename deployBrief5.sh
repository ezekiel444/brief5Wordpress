#!/bin/bash
#Run this script with 'bash and the script name. E.g bash name.sh'

az login

echo "Enter a resource group name e.g yourname"
read nameRG

#-----------------------------------------------------------

echo "Enter my network interface name"
read nameNetworkInterface


#-----------------------------------------------------------



echo "Enter a name for your virtual machine"
read vmName


#-----------------------------------------------------------


echo "Enter a password for virtual machine and mariadb a strong one else it will fail"
read -s password

#-----------------------------------------------------------



echo "how many machines?"
read vmNum


#-----------------------------------------------------------



echo "Enter database name in small letters"
read nameDB


#-----------------------------------------------------------


echo "Enter mariadb username in small letters"
read nameUserDB


#-----------------------------------------------------------


az group create \
    --name $nameRG \
    --location westus3

    #Create virtual network

    az network vnet create \
    --resource-group $nameRG \
    --location westus3 \
    --name myVNet \
    --address-prefixes 10.1.0.0/16 \
    --subnet-name myBackendSubnet \
    --subnet-prefixes 10.1.0.0/24


    #Create a public IP address

   az network public-ip create \
    --resource-group $nameRG \
    --name myPublicIP \
    --sku Standard \
    --zone 1

     #Create the load balancer resource

     az network lb create \
    --resource-group $nameRG \
    --name myLoadBalancer \
    --sku Standard \
    --public-ip-address myPublicIP \
    --frontend-ip-name myFrontEnd \
    --backend-pool-name myBackEndPool


     #Create the health probe

    az network lb probe create \
    --resource-group $nameRG \
    --lb-name myLoadBalancer \
    --name myHealthProbe \
    --protocol tcp \
    --port 80


      #Create a load balancer rule 

     az network lb rule create \
    --resource-group $nameRG \
    --lb-name myLoadBalancer \
    --name myHTTPRule \
    --protocol tcp \
    --frontend-port 80 \
    --backend-port 80 \
    --frontend-ip-name myFrontEnd \
    --backend-pool-name myBackEndPool \
    --probe-name myHealthProbe \
    --disable-outbound-snat true \
    --idle-timeout 15 \
    --enable-tcp-reset true

     #Create a network security group

    az network nsg create \
    --resource-group $nameRG \
    --name myNSG


       #Create a network security group rule

     az network nsg rule create \
    --resource-group $nameRG \
    --nsg-name myNSG \
    --name myNSGRuleHTTP \
    --protocol '*' \
    --direction inbound \
    --source-address-prefix '*' \
    --source-port-range '*' \
    --destination-address-prefix '*' \
    --destination-port-range 80 \
    --access allow \
    --priority 200

    #Create a bastion host:
    
     #Create a public IP address for bastion

    az network public-ip create \
        --resource-group $nameRG \
        --name myBastionIP \
        --sku Standard \
        --zone 1

     #Create a bastion subnet

      az network vnet subnet create \
    --resource-group $nameRG \
    --name AzureBastionSubnet \
    --vnet-name myVNet \
    --address-prefixes 10.1.1.0/27
    

    #Create bastion host

     az network bastion create \
    --resource-group $nameRG \
    --name myBastionHost \
    --public-ip-address myBastionIP \
    --vnet-name myVNet \
    --location westus3

#A loop to create network interface, virtual machine and a backend pool in load balancer

for((i=1; i<=vmNum; i++)); do
 #Create backend servers
        #Create network interfaces for the virtual machines

    az network nic create \
        --resource-group $nameRG \
        --name $nameNetworkInterface$i \
        --vnet-name myVNet \
        --subnet myBackEndSubnet \
        --network-security-group myNSG
  
   #Create virtual machine

    az vm create \
    --resource-group $nameRG \
    --name $vmName$i \
    --nics $nameNetworkInterface$i \
    --image Debian:debian-11:11-gen2:0.20210928.779 \
    --admin-username $vmName \
    --admin-password $password \
    --public-ip-sku Standard 

    #Open port 80 and port 22 for web traffic

az vm open-port --port 80 --resource-group $nameRG --name $vmName$i
az vm open-port --port 22 --resource-group $nameRG --name $vmName$i

 #add_virtual machines to load balancer backend pool

 az network nic ip-config address-pool add \
     --address-pool myBackendPool \
     --ip-config-name ipconfig1 \
     --nic-name $nameNetworkInterface$i \
     --resource-group $nameRG \
     --lb-name myLoadBalancer
done

#Create NAT gateway:

    #Create public IP

   az network public-ip create \
    --resource-group $nameRG \
    --name myNATgatewayIP \
    --sku Standard \
    --zone 1


    #Create NAT gateway resource
    
     az network nat gateway create \
    --resource-group $nameRG \
    --name myNATgateway \
    --public-ip-addresses myNATgatewayIP \
    --idle-timeout 10

    #Associate NAT gateway with subnet

    az network vnet subnet update \
    --resource-group $nameRG \
    --vnet-name myVNet \
    --name myBackendSubnet \
    --nat-gateway myNATgateway

#_add a multiple VMs inbound NAT rule

#for backend access

    az network lb inbound-nat-rule create \
        --backend-port 22 \
        --lb-name myLoadBalancer \
        --name sshConntionPort \
        --protocol Tcp \
        --resource-group $nameRG \
        --backend-pool-name myBackendPool \
        --frontend-ip-name myFrontend \
        --frontend-port-range-end 1000 \
        --frontend-port-range-start 500

        #for fontend access

        az network lb inbound-nat-rule create \
        --backend-port 80 \
        --lb-name myLoadBalancer \
        --name httpConnectionPort \
        --protocol Tcp \
        --resource-group $nameRG \
        --backend-pool-name myBackendPool \
        --frontend-ip-name myFrontend \
        --frontend-port-range-end 1000 \
        --frontend-port-range-start 500  

         #Create an Azure Database for MariaDB server

    az mariadb server create --resource-group $nameRG --name $nameDB  --location westus3 --admin-user $nameUserDB --admin-password $password --sku-name GP_Gen5_2 --version 10.2

    #Configure a firewall rule

    az mariadb server firewall-rule create --resource-group $nameRG --server $nameDB --name AllowMyIP --start-ip-address 192.168.0.1 --end-ip-address 192.168.0.1

    #Configure SSL settings

    az mariadb server update --resource-group $nameRG --name $nameDB --ssl-enforcement Disabled

    az mariadb server show --resource-group $nameRG --name $nameDB

    #Connect to the server by using the mysql command-line tool

    #mysql -h mydemoserver.mariadb.database.azure.com -u myadmin@mydemoserver -p
