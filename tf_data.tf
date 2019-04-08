## References to self/kops managed resources.
variable "aws_profile" {
  description = "Name of the AWS profile to be used for the current terraform run"
  default = "default"
}

variable "aws_default_region" {
  description = "Name of region"
  default = "default"
}

data "aws_availability_zones" "available" {}

##
## SELF MANAGED RESOURCES
##

# Route53 Hosted Zone of the domain for services
data "aws_route53_zone" "service" {
  name = "${var.kubernetes_ingress_domain}."
}

# Certificate of the domain for services
data "aws_acm_certificate" "service" {
  domain = "${var.kubernetes_ingress_domain}"
}

##
## KOPS MANAGED RESOURCES
##

# VPC for the Kubernetes cluster
data "aws_vpc" "kops_vpc" {
  tags {
    Environment = "${var.environment}"
    Name = "<<Name tag>>"
  }
}

# Subnets for the Kubernetes cluster
data "aws_subnet_ids" "kops_subnets" {
  vpc_id = "${data.aws_vpc.kops_vpc.id}"
  tags = "${map("kubernetes.io/cluster/${var.kubernetes_cluster_name}", "shared")}"
}

# Auto Scaling Group for the Kubernetes nodes
data "aws_autoscaling_groups" "kops_nodes" {
  filter {
    name   = "key"
    values = ["Name"]
  }

  filter {
    name   = "value"
    values = ["${formatlist("nodes-%s.%s", data.aws_availability_zones.available.names, var.kubernetes_cluster_name)}"]
  }
}

# Security Group for the Kubernetes masters
data "aws_security_group" "kops_masters" {
  tags {
    Name = "masters.${var.kubernetes_cluster_name}"
  }
}

# Security Group for the Kubernetes nodes
data "aws_security_group" "kops_nodes" {
  tags {
    Name = "nodes.${var.kubernetes_cluster_name}"
  }
}

