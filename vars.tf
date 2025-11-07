variable "AWS_REGION" {}

variable "AWS_ACCESS_KEY" {}

variable "AWS_SECRET_KEY" {}

variable "LoadbalancerSG" {
    default = "LBSG"
}

variable "EC2SG" {
    default = "Ec2nstancesg"
}

variable "Bastion" {
  default = "Bastionsg"
}

variable "EFS" {
    default = "EFSSG"
  
}

variable "RDS" {
  default = "RDSSG"
}