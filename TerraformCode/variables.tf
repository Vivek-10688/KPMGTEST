// Variable's For VPC
variable "aws_region" {
  default = "us-east-1"
}

variable "create_vpc" {
  description = "Controls If VPC Should Be Created."
  type        = bool
  default     = true
}
variable "vpc_name" {
  type        = string
  default     = "Terraform"
  description = "VPC Build For Terraform Demo"
}
variable "default_cidr" {
  type    = string
  default = "0.0.0.0/0"
}
variable "vpc_ipv4_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "create_igw" {
  description = "Controls If An Internet Gateway Should Be Created."
  type        = bool
  default     = true
}

variable "cidr_first_two_octet" {
  type    = string
  default = "10.0"
}
data "aws_availability_zones" "available" {
  state = "available"
}
variable "map_public_ip_on_launch" {
  description = "Auto-Assign Public IP On EC2 launch"
  type        = bool
  default     = true
}
variable "public_subnet_name" {
  description = "Public Subnets Name"
  type        = string
  default     = "public"
}
locals {

  /*Incremental value by count of index "+ 1" in third octet to match with what number of AZ in each region and
create the subnet accordingly it but must match wiht maximum_public_subnets_tobecreated counter.*/
  public_subnets_cidr_incrementalvalue = 1
  maximum_public_subnets_tobecreated   = 1
  availability_zones                   = data.aws_availability_zones.available.names
  public_subnets = [
    /* for loop to go by each element in array of AZ*/
    for az in local.availability_zones :
    /* Create A Condition which will pick first two octet and in 
    third octet it will increase the value by 1 as per AZ but not exceeding the max subnets variable.*/
    "${var.cidr_first_two_octet}.${local.public_subnets_cidr_incrementalvalue + index(local.availability_zones, az)}.0/24"
    if index(local.availability_zones, az) < local.maximum_public_subnets_tobecreated
  ]
}

variable "manage_default_route_table" {
  description = "Manage Default Route Table"
  type        = bool
  default     = true
}
variable "default_route_table_routes" {
  description = "Update Or Map Internet Gateway Route."
  type        = list(map(string))
  default = [
    {
      cidr_block = "0.0.0.0/0"
    }
  ]
}

// Variable's For Security

# For Network ACL - Define Array Of Rules
locals {
  nacl_ingress_rules = [
    { rule_num : 100, protocol : "-1", portfrom : 0, portto : 0, cidr_block : var.default_cidr, action : "allow" }
  ]
}
locals {
  nacl_egress_rules = [
    { rule_num : 100, protocol : "-1", portfrom : 0, portto : 0, cidr_block : var.default_cidr, action : "allow" }
  ]
}

# For Security Group - Define Array Of Rules
locals {
  sg_ingress_rules = [
    { protocol : "tcp", portfrom : 80, portto : 80, cidr_blocks : ["0.0.0.0/0"], description : "For Incoming HTTP Connection" },
    { protocol : "tcp", portfrom : 22, portto : 22, cidr_blocks : ["0.0.0.0/0"], description : "For Incoming SSH Connection" }
  ]
}
locals {
  sg_egress_rules = [
    { protocol : "-1", portfrom : 0, portto : 0, cidr_blocks : ["${var.default_cidr}"], description : "For Outgoing Connection" }
  ]
}

// Variable's For EC2
variable "instance_count" {
  default = "1"
}
variable "instance_type" {
  default = "t2.micro"
}
variable "tenancy" {
  description = "EC2 Tenancy."
  type        = string
  default     = "default"
}
variable "instance_initiated_shutdown_behavior" {
  description = "Shutdown behavior for the instance"
  type        = string
  default     = "stop"
}
variable "disable_api_termination" {
  description = "Protect EC2 From Deletion If Enables"
  type        = bool
  default     = false
}

variable "use_num_suffix" {
  description = "Add Numerical Value To EC2 Instance With Incremental By 1"
  type        = bool
  default     = false
}
variable "num_suffix_format" {
  description = "Numerical suffix format used as the volume and EC2 instance name suffix"
  type        = string
  default     = "-%d"
}
variable "tags" {
  description = "List Of Tags"
  type        = map(string)
  default     = {}
}
variable "enable_volume_tags" {
  description = "EBS Tagging"
  type        = bool
  default     = true
}
variable "volume_tags" {
  description = "List Of Tags To EBS At Launch Time"
  type        = map(string)
  default     = {}
}
