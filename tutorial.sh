# Create VPC and Subnets
gcloud compute networks create griffin-dev-vpc --subnet-mode=custom
gcloud compute networks create griffin-prod-vpc --subnet-mode=custom

gcloud compute networks subnets create griffin-dev-wp --network=griffin-dev-vpc --region=us-east1 --range=192.168.16.0/20
gcloud compute networks subnets create griffin-dev-mgmt --network=griffin-dev-vpc --region=us-east1 --range=192.168.32.0/20

gcloud compute networks subnets create griffin-prod-wp --network=griffin-prod-vpc --region=us-east1 --range=192.168.48.0/20
gcloud compute networks subnets create griffin-prod-mgmt --network=griffin-prod-vpc --region=us-east1 --range=192.168.64.0/20

# Firewal rules
gcloud compute firewall-rules create griffin-dev-vpc-allow-icmp-ssh-rdp \
 --direction=INGRESS \
 --priority=1000 \
 --network=griffin-dev-vpc \
 --action=ALLOW --rules=icmp,tcp:22,tcp:3389 --source-ranges=0.0.0.0/0

gcloud compute firewall-rules create griffin-prod-vpc-allow-icmp-ssh-rdp \
 --direction=INGRESS \
 --priority=1000 \
 --network=griffin-prod-vpc \
 --action=ALLOW --rules=icmp,tcp:22,tcp:3389 --source-ranges=0.0.0.0/0

# Create bastion host
gcloud compute instances create bastion-vm --zone=us-east1-b \
  --machine-type=n1-standard-4 \
  --network-interface subnet=griffin-dev-mgmt \
  --network-interface subnet=griffin-prod-mgmt

# Cloud SQL
gcloud sql instances create griffin-dev-db --region=us-east1
gcloud sql users set-password root --host=% --instance griffin-dev-db --password root
gcloud sql connect griffin-dev-db --user=root
# sql command
CREATE DATABASE wordpress;
GRANT ALL PRIVILEGES ON wordpress.* TO "wp_user"@"%" IDENTIFIED BY "stormwind_rules";
FLUSH PRIVILEGES;

# GKE
gcloud container clusters create griffin-dev \
    --machine-type n1-standard-4 \
    --zone us-east1-b \
    --num-nodes 2 \
    --network griffin-dev-vpc \
    --subnetwork griffin-dev-wp \
    --node-locations us-east1-b \
    --enable-ip-alias

#!/bin/bash
gsutil cp -R gs://cloud-training/gsp321/wp-k8s .
cd wp-k8s

# [edit wp.env yaml]
# ganti username dan password dengan wp_user dan stormwind_rules

gcloud container clusters get-credentials griffin-dev --zone=us-east1-b
kubectl apply -f wp-env.yaml

gcloud iam service-accounts keys create key.json \
    --iam-account=cloud-sql-proxy@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
kubectl create secret generic cloudsql-instance-credentials \
    --from-file key.json

# [edit wp-deployment.yaml]
# ganti YOUR_INSTANCE_NAME menjadi Cloud SQL Connection String
# didapat dari console Cloud SQL

kubectl create -f wp-deployment.yaml
kubectl create -f wp-service.yaml

kubectl get svc # di sini catat external IP dari service wordpress !

sisanya cek di sini karena GUI semuanya
https://chriskyfung.github.io/blog/qwiklabs/Set-up-and-Configure-a-Cloud-Environment-in-Google-Cloud-Challenge-Lab