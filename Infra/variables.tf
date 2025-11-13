variable "aws_region" {
  description = "aws selcted region"
  default = "us-east-1"
}
variable "instance_type" {
  description = "Type of AWS EC2 instance"
  default     = "t3.micro"
}
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}
variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  default = "10.0.1.0/24"
}
variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  default = "10.0.2.0/24"
}
variable "own_ip" {
  description = "CIDR block for IP address for accessing the Jenkins instance. Replace with your own IP address"
  default = "77.137.66.88/32"
}
variable "public_az" {
  description = "public subnet AZ"
  default = "us-east-1a"
}
variable "private_az" {
  description = "private subnet AZ"
  default = "us-east-1a"
}