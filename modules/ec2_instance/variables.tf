variable "ami_value" {
  description = "value for AMI"
  default = "ami-04a81a99f5ec58529"
}

variable "instance_type_value" {
  description = "value for instance type"
  default = "t2.micro"
}

variable "cidr" {
  description = "value of CIDR"
  default = "10.0.0.0/16"
  
}
