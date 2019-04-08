## Environment specific values.
set -x

# Environment
export environment=dev

# Domain name for the external ALB.
export kubernetes_ingress_domain=dev.example.com

# Kubernetes cluster name.
export kubernetes_cluster_name=dev.example.com

# Bucket name for state store of kops and Terraform.
#export state_store_bucket_name="state.$kubernetes_cluster_name"
export state_store_bucket_name="dev-infra-state-store"

# AWS Profile.
#export AWS_PROFILE=default

# AWS Region.
export AWS_DEFAULT_REGION=us-east-2

# Kafka brokers
export KAFKA_BROKERS="<<comma seperated list of kafka broker ips>>"

# Kafka topic
export KAFKA_TOPIC=dev-infra-logs

# VPC id
export vpc_id="<<vpc id>>"

# Subnet ids
export subnet_ids="<<comma seperated list of subnet_ids>>"

# ssl certificate arn
export ssl_certificate_arn="<<ssl certificate arn>>"

## OIDC provider for Kubernetes Dashboard and Kibana.
## See also https://github.com/int128/kubernetes-dashboard-proxy
#export oidc_discovery_url=https://accounts.google.com
#export oidc_kubernetes_dashboard_client_id=xxx-xxx.apps.googleusercontent.com
#export oidc_kubernetes_dashboard_client_secret=xxxxxx
#export oidc_kibana_client_id=xxx-xxx.apps.googleusercontent.com
#export oidc_kibana_client_secret=xxxxxx


# Load environment values excluded from VCS
if [ -f .env ]; then
  source .env
fi

## Environment variables for tools.

# kops
export KOPS_STATE_STORE="s3://$state_store_bucket_name"
export KOPS_CLUSTER_NAME="$kubernetes_cluster_name"

# Terraform
export TF_VAR_state_store_bucket_name="$state_store_bucket_name"
export TF_VAR_kubernetes_ingress_domain="$kubernetes_ingress_domain"
export TF_VAR_kubernetes_cluster_name="$kubernetes_cluster_name"
export TF_VAR_environment="$environment"
export TF_VAR_aws_default_region="$AWS_DEFAULT_REGION"

# kubectl
export KUBECONFIG="$(pwd)/envs/$environment/.kubeconfig"

# Use binaries in .bin
export PATH="$(pwd)/.bin:$PATH"


set +x
