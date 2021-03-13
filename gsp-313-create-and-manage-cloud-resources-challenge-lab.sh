# Config
gcloud config set compute/region us-east1
gcloud config set compute/zone us-east1-b

# Task 1: Create a project jumphost instance
gcloud compute instances create nucleus-jumphost \
  --machine-type=f1-micro

# Task 2: Create a Kubernetes service cluster
gcloud container clusters create nucleus-clusters
gcloud container clusters get-credentials nucleus-clusters

kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:2.0
kubectl expose deployment hello-server --type=LoadBalancer --port 8080

# Task 3: Set up an HTTP load balancer
cat << EOF > startup.sh
#! /bin/bash
apt-get update
apt-get install -y nginx
service nginx start
sed -i -- 's/nginx/Google Cloud Platform - '"\$HOSTNAME"'/' /var/www/html/index.nginx-debian.html
EOF

gcloud compute instance-templates create nginx-template \
   --metadata-from-file startup-script=startup.sh

gcloud compute target-pools create nginx-pool

gcloud compute instance-groups managed create nginx-group \
   --base-instance-name nginx \
   --template=nginx-template \
   --target-pool=nginx-pool \
   --size=2

gcloud compute firewall-rules create www-firewall --allow tcp:80

gcloud compute forwarding-rules create nginx-lb \
    --ports=80 \
    --target-pool nginx-pool

gcloud compute http-health-checks create http-basic-check

gcloud compute instance-groups managed \
    set-named-ports nginx-group \
    --named-ports http:80

# gcloud compute firewall-rules create fw-allow-health-check \
#     --network=default \
#     --action=allow \
#     --direction=ingress \
#     --source-ranges=130.211.0.0/22,35.191.0.0/16 \
#     --target-tags=allow-health-check \
#     --rules=tcp:80

# gcloud compute addresses create lb-ipv4-1 \
#     --ip-version=IPV4 \
#     --global

# gcloud compute health-checks create http http-basic-check \
#     --port 80

gcloud compute backend-services create nginx-backend \
    --protocol HTTP --http-health-checks http-basic-check --global

gcloud compute backend-services add-backend nginx-backend \
    --instance-group nginx-group \
    --instance-group-zone us-east1-b \
    --global


# gcloud compute backend-services create web-backend-service \
#     --protocol=HTTP \
#     --port-name=http \
#     --health-checks=http-basic-check \
#     --global

# gcloud compute backend-services add-backend web-backend-service \
#     --instance-group=nucleus-webserver \
#     --instance-group-zone=us-east1-b \
#     --global

gcloud compute url-maps create web-map \
    --default-service nginx-backend

gcloud compute target-http-proxies create http-lb-proxy \
    --url-map web-map

# gcloud compute url-maps create web-map-http \
#     --default-service web-backend-service

# gcloud compute target-http-proxies create http-lb-proxy \
#     --url-map web-map-http

gcloud compute forwarding-rules create http-content-rule \
    --global \
    --target-http-proxy http-lb-proxy \
    --ports 80

# gcloud compute forwarding-rules create http-content-rule \
#     --address=lb-ipv4-1\
#     --global \
#     --target-http-proxy=http-lb-proxy \
#     --ports=80


# References:
# https://typed-assignment.blogspot.com/2020/10/create-and-manage-cloud-resources-tech-ed.html
