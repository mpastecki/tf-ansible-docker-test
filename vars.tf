variable "AWS_ACCESS_KEY" {}

variable "AWS_SECRET_KEY" {}

variable "AWS_REGION" {
  default = "eu-west-1"
}
variable "PATH_TO_PRIVATE_KEY" {
  default = "/home/mpastecki/.ssh/id_rsa"
}
variable "PATH_TO_PUBLIC_KEY" {
  default = "/home/mpastecki/.ssh/id_rsa.pub"
}
variable "AMIS" {
  type = "map"
  default = {
   eu-west-1 = "ami-8fd760f6"
  }
}

variable "cluster_manager_count" {
    description = "Number of manager instances for the swarm cluster."
    default = 1
}

variable "cluster_node_count" {
    description = "Number of node instances for the swarm cluster."
    default = 3
}

# Name of the ansible inventory to use when provisioning the VMs
variable "ansible_inventory_name" {
    default = "test"
}
