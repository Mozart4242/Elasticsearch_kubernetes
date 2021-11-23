echo "This is a simple bash script to automate the elasticsearch deployment on an existing kubernetes cluster"
echo "Picnic Company"

#echo "This approach is going to connect to an NFS Storage over '10.132.160.227' on '/mnt/nfs_share' path"
echo "First we are going to install some packages using 'apt'"
read -p "Press any key to start"
mkdir ~/nfs_share
#mount -t nfs 10.132.160.227:/mnt/nfs_share ~/nfs_share
# All files must be available on the NFS mount point

apt update && apt install helm -y
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
apt update && apt install -y kubectl=1.19.2-00

echo "a list of deployments using helm"
helm list
read -p "Enter the name of your helm list exactly the way it is: " hlist
echo "SELECTED: $hlist"
sleep 1
echo "[0] Deploy"
echo "[1] Upgrade"
read -p ">> " select

if [[ ( $select == 0 || $select == 1 ) ]];
then  
        echo "This is going to Deploy the elasticsearch cluster from scratch"
        echo "This is not going to change the template helm configuration file"
        sleep 1
        read -p "Enter the name of your elasticsearch cluster: " name
        read -p "Enter a name for your helm deployment: " hname
        if [ $select == 0 ];
            helm install $hname ~/nfs_share/kubernetes/elasticsearch-7.5.2.tgz -f els-values.yaml --set clusterName=$name --set replicas=$replica
            sleep 1
        if [ $select == 1 ];
            helm upgrade $hname ~/nfs_share/kubernetes/elasticsearch-7.5.2.tgz -f els-values.yaml --set clusterName=$name --set replicas=$replica
        
        kubectl get svc 
        kubectl get pods -o wide -w
        
else echo "Please Enter a Number From The List" >&2; exit 1
fi
