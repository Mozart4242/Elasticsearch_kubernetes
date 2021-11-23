
# Elasticsearch on K8S

This file is going to explain the setup proccess
## Environment
| Role     | IP     | DNS name  |     OS    | RAM         |CPU|
| ---------| ------ |----|-------|-------------|----|
| Load Balancer|  10.132.132.100 |-  |Ubuntu server 20.04 LTS |     8G    | 8   |
| Master    |  10.132.132.101 | kmaster1 |Ubuntu server 20.04 LTS |     8G    | 8   |
| Master    |  10.132.132.102 | kmaster2 |Ubuntu server 20.04 LTS |     8G    | 8   |
| Worker    |  10.132.132.103 |kworker1  |Ubuntu server 20.04 LTS |     8G    | 8   |
| Worker    |  10.132.132.104 |  kworker2|Ubuntu server 20.04 LTS |     8G    | 8   |


## Approach
- This Implementation is based on multiple Virtual Machines
- Deploying elasticsearch using kubernetes statefulset
- Persistent Volumes : **LOCAL**
- Recomended Persistent Volume in cloud environment: *awsElasticBlockStore*
- Recomended Persistent Volume in on-premise environment: *glusterfs*

## Design Overview
![overview](https://user-images.githubusercontent.com/44939554/143050115-7f5e78d9-3e7d-4ad8-a2e6-70c75e18e8b6.png)

## Persisten Volume
![Picture1](https://user-images.githubusercontent.com/44939554/143050411-348c6b81-d025-41a5-be6e-0b19320de51b.png)

## Services
![Picture2](https://user-images.githubusercontent.com/44939554/143050635-db61e283-81ea-4a80-8aa3-954163e242b6.png)

##  Set up load balancer node

Set up load balancer node

```bash
  apt update && apt install -y haproxy
```

Configure haproxy

Append the below lines to /etc/haproxy/haproxy.cfg

    frontend kubernetes-frontend
        bind 10.132.132.100:6443
        mode tcp
        option tcplog
        default_backend kubernetes-backend

    backend kubernetes-backend
        mode tcp
        option tcp-check
        balance roundrobin
        server kmaster1 10.132.132.101:6443 check fall 3 rise 2
        server kmaster2 10.132.132.102:6443 check fall 3 rise 2


##  On all kubernetes nodes (kmaster1, kmaster2, kworker1, kworker2)
Update sysctl settings for Kubernetes networking

    cat >>/etc/sysctl.d/kubernetes.conf<<EOF
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    EOF
    sysctl --system

Install docker engine

    {
    apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt update && apt install -y docker-ce=5:19.03.10~3-0~ubuntu-focal containerd.io
    }

Add Apt repository

    {
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
    }

Install Kubernetes components

    apt update && apt install -y kubeadm=1.19.2-00 kubelet=1.19.2-00 kubectl=1.19.2-00

##  On master node (kmaster1)
Initialize Kubernetes Cluster

    kubeadm init --control-plane-endpoint="10.132.132.100:6443" --upload-certs --apiserver-advertise-address=10.132.132.101 --pod-network-cidr=192.168.0.0/16

Deploy Calico network

    kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.projectcalico.org/v3.15/manifests/calico.yaml

Join other nodes to the cluster (kmaster2 & kworker1 & kworker2)

##  Downloading kube config to your local machine

    mkdir ~/.kube
    scp kadmin@10.132.132.101:/etc/kubernetes/admin.conf ~/.kube/config

## Setup Nginx as the simulated cloud Load Balancer

Download and install Nginx
    
    apt install nginx

create a site in nginx

    vi /etc/ngin/sites-available/mysite

    upstream elasticsearch {
     server 10.132.132.101:30000;
     server 10.132.132.102:30000;
     server 10.132.132.103:30000;
     server 10.132.132.104:30000;
    }

    server {
    listen 9200 ssl;
    server_name domain_name;
    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;    

    location / {
      proxy_pass http://elasticsearch;
      auth_basic "Restricted Content";
      auth_basic_user_file /etc/nginx/.htpasswd;
        }
    }

## Deploy Elasticsearch using Helm
First install helm and then download elasticsearch helm package

    wget https://helm.elastic.co/helm/elasticsearch/elasticsearch-7.5.2.tgz

unzip the downloaded package

    tar -xvf elasticsearch-7.5.2.tgz

Edit the "values.yaml" file

    >> clusterName: "picnic"

    >> replicas: 2

    >> minimumMasterNodes: 1

    >> resources:
        requests:
            cpu: "1000m"
            memory: "2Gi"
        limits:
            cpu: "1000m"
            memory: "2Gi"

    >> volumeClaimTemplate:
        accessModes: [ "ReadWriteOnce" ]
        storageClassName: local-storage
        resources:
            requests:
             storage: 5Gi
    
    >> persistence:
            enabled: true
    
    >> service:
        labels: {}
        labelsHeadless: {}
        type: LoadBalancer
        nodePort: "30000"
        annotations: {}
        httpPortName: http
        transportPortName: transport
    
## Create the persistent volume manifest

- download the manifest from the provided file

- deploy the Persistent Volume manifest

        kubectl apply -f elasticsearch-pv.yaml



## Install Elasticsearch using helm

    helm install els elaelasticsearch-7.5.2.tgz -f values.yaml


## Authors

- [mozart4242](https://linkedin.com/in/mozart4242)

