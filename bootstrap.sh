#!/bin/bash
#
# Bootstrap the Kubernetes cluster and AWS resources.
# See README.
#
if [ -z "$KOPS_CLUSTER_NAME" ]; then
  echo "Run the following command before running $0"
  echo '  source envs/${environment}/variables.sh'
  exit 1
fi

set -e
set -o pipefail
set -x
cd "$(dirname "$0")"

# Show versions
kops version
terraform version
helm version -c
helmfile -v

# Generate a key pair to connect to EC2 instances
if [ ! -f .sshkey ]; then
  ssh-keygen -f envs/$environment/.sshkey -N ''
fi

# Create a cluster configuration
kops create cluster \
  --name "$KOPS_CLUSTER_NAME" \
  --zones "${AWS_DEFAULT_REGION}a,${AWS_DEFAULT_REGION}b" \
  --master-zones "${AWS_DEFAULT_REGION}a,${AWS_DEFAULT_REGION}b" \
  --authorization RBAC \
  --ssh-public-key envs/$environment/.sshkey.pub \
  --node-count 1 \
  --master-count=3 \
  --master-size t2.medium \
  --vpc=${vpc_id} \
  --subnets=${subnet_ids} \
  --networking=calico \
  --node-volume-size=30 \
  --api-ssl-certificate=$ssl_certificate_arn


# Make single AZ nodes
kops create instancegroup "nodes-${AWS_DEFAULT_REGION}a" --name "$KOPS_CLUSTER_NAME" --subnet "${AWS_DEFAULT_REGION}a" --edit=false
kops delete instancegroup nodes --name "$KOPS_CLUSTER_NAME" --yes

# Create AWS resources
kops update cluster --name "$KOPS_CLUSTER_NAME" --yes

# Make sure you can access to the cluster
while ! kops validate cluster --name "$KOPS_CLUSTER_NAME"; do
  echo "Waiting until the cluster is available..."
  sleep 30
done

# Remove terraform.tfstate
if [ ! -f ./.terraform/terraform.tfstate ]; then
  rm -r ./.terraform/terraform.tfstate
fi

# Initialize Terraform
terraform init -backend-config="bucket=$TF_VAR_state_store_bucket_name" -backend-config="region=$TF_VAR_aws_default_region"

# Create AWS resources
terraform apply -auto-approve

# Initialize Helm
kubectl create -f templates/helm-service-account.yaml
helm init --service-account tiller
sleep 30
helm version

# Install Helm charts

helm upgrade --install stable/nginx-ingress --name ingress-nginx-aml -f envs/$environment/ingress-values.yaml --namespace ingress-nginx
helm upgrade --install stable/nginx-ingress --name ingress-nginx-aml --namespace ingress-nginx

helm upgrade --install logging-fluent-bit ./charts/fluent-bit/ -f envs/$environment/ingress-values.yaml --namespace logging
helm upgrade --install logging-fluent-bit ./charts/fluent-bit/ --namespace logging
