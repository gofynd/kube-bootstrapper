#!/bin/bash
#
# Bootstrap the Kubernetes cluster and AWS resources.
# See README.
#
is_env_set="yes"

function echo_message () {
  if [[ $is_env_set == "yes" ]]
  then
    echo 'Success!!!!'
  else
    echo 'Failed!!!!'
  fi
}

if [ -z "$AWS_PROFILE" ]; then
  is_env_set="no"
  echo "Please export AWS_PROFILE and ENVIRONMENT env variable and run following command"
  echo '  source envs/${ENVIRONMENT}/variables.sh'
  echo_message
  exit 1
fi

if [ -z "$KOPS_CLUSTER_NAME" ]; then
  is_env_set="no"
  echo "Run the following command before running $0"
  echo '  source envs/${ENVIRONMENT}/variables.sh'
  echo_message
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

# Initialize kubecontext
kops export kubecfg
kops validate cluster

# Remove terraform.tfstate
if [ -d ./.terraform ]; then
  if [ ! -f ./.terraform/terraform.tfstate ]; then
    rm -r ./.terraform/terraform.tfstate
  fi
fi

# Initialize Terraform
terraform init -backend-config="bucket=$TF_VAR_state_store_bucket_name" -backend-config="region=$TF_VAR_aws_default_region"

# Initialize Helm
helm init --client-only

echo_message