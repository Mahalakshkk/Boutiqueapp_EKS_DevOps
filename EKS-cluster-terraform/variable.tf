variable "region" {
  default = "ap-northeast-1"
}

variable "cluster_name" {
  default = "demo-cluster"
}

variable "subnet_ids" {
  type = list(string)
}

variable "node_instance_type" {
  default = "m7i-flex.large"
}
