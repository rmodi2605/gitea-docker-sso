# Create VPC Network and Subnet in '1a' AZ
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name = "${var.env_prefix}_vpc"
  cidr = var.vpc_cidr_block

  azs            = [var.avail_zone]
  public_subnets = [var.vpc_pubic_subnet]
  public_subnet_tags = {Name = "${var.env_prefix}_vpc_subnet"}

  default_route_table_tags = {Name = null} 
  public_route_table_tags = {Name = "${var.env_prefix}_vpc_rt"}
  igw_tags = {Name = "${var.env_prefix}_vpc_igw"}
  tags = {Name = "${var.env_prefix}_vpc"}

}

# Modify Security Group to Allow ICMP, SSH, HTTP and HTTPS port for ingress
resource "aws_default_security_group" "rmodi_vpc_sg" {
    vpc_id = module.vpc.vpc_id

    ingress {
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
        from_port = 22
        to_port = 22
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    ingress {
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "icmp"
        from_port = -1
        to_port = -1
    }

    egress {
        cidr_blocks = ["0.0.0.0/0"]
        protocol    = -1
        from_port   = 0
        to_port     = 0
  }
   
   tags = {
    Name = "${var.env_prefix}_vpc_sg"
   }
}

# Create SSH key Pair for EC2
resource "aws_key_pair" "terraform_Key" {
    key_name = "${var.env_prefix}_ssh_key"
    public_key = file(var.pub_ssh_key_location)
}

# Create EC2 Instance
resource aws_instance "rmodi_vm" {
    instance_type = var.instance_type
    ami = var.ami_type  
    
    subnet_id = module.vpc.public_subnets[0]
    availability_zone = module.vpc.azs[0]
    vpc_security_group_ids = module.vpc.default_vpc_default_security_group_id
    
    associate_public_ip_address = true
    key_name = aws_key_pair.terraform_Key.key_name
    
    tags = {
        Name = "${var.env_prefix}_vm"
    } 
}

#Output Public IP of EC2 Instance once it's Created
output "EC2_Public_IP" {
    value = aws_instance.rmodi_vm.public_ip
}
