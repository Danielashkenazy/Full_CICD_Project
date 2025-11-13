provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "main_vpc"
  }
}

####Subnets####
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.private_az
  tags = {
    Name = "private_subnet"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = var.public_az
  tags = {
    Name = "public_subnet"
  }
}

####Internet Gateway and NAT gateway####
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main_igw"
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "NatEIP"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "main_nat_gateway"
  }
}

####Route Tables####
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public_route_table"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "private_route_table"
  }
}

####Route Table Associations####
resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_rta" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_rt.id
}

####Ubuntu AMI####
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

####Shared SSH Key for debugging####
resource "tls_private_key" "jenkins_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "jenkins_shared_key" {
  key_name   = "jenkins-shared-key"
  public_key = tls_private_key.jenkins_key.public_key_openssh
}

resource "local_file" "private_key_pem" {
  content         = tls_private_key.jenkins_key.private_key_pem
  filename        = "${path.module}/jenkins-shared-key.pem"
  file_permission = "0600"
}

####Jenkins Instance####
resource "aws_instance" "jenkins_instance" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.jenkins_profile.name
  key_name                    = aws_key_pair.jenkins_shared_key.key_name
  
  tags = {
    Name = "Jenkins_Instance"
  }
  
  user_data = templatefile("../jenkins/jenkins_user_data.sh.tmpl", {
    
    ecr_url = aws_ecr_repository.app_repository.repository_url
  })
}


resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg"
  description = "Allow Jenkins access"
  vpc_id      = aws_vpc.main.id

  # חוקים פנימיים בלבד — גישה מבחוץ או מהמחשב שלך
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.own_ip]
    description = "SSH from admin"
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.own_ip]
    description = "Jenkins web UI from your IP"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins_sg"
  }
}
####App EC2 Instance####
resource "aws_instance" "app_instance" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  associate_public_ip_address = false
  iam_instance_profile = aws_iam_instance_profile.app_profile.name

  key_name                    = aws_key_pair.jenkins_shared_key.key_name
  
  tags = {
    Name = "App_Instance"
  }
  
  # Pass Jenkins private IP to the script
  user_data = templatefile("${path.module}/app_user_data.sh.tmpl", {
    jenkins_private_ip = aws_instance.jenkins_instance.private_ip
  })
  
  # CRITICAL: App must start AFTER Jenkins
  depends_on = [aws_instance.jenkins_instance]
}

resource "aws_security_group" "app_sg" {
  name        = "app_sg"
  description = "Allow App access"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app_sg"
  }
}

####Additoinal Security Group Rules####
resource "aws_security_group_rule" "jenkins_allow_app_ui" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.jenkins_sg.id
  source_security_group_id = aws_security_group.app_sg.id
  description              = "App can access Jenkins web UI"
}

resource "aws_security_group_rule" "jenkins_allow_app_jnlp" {
  type                     = "ingress"
  from_port                = 50000
  to_port                  = 50000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.jenkins_sg.id
  source_security_group_id = aws_security_group.app_sg.id
  description              = "App can connect to Jenkins JNLP port"
}


resource "aws_security_group_rule" "app_allow_ssh_from_jenkins" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app_sg.id
  source_security_group_id = aws_security_group.jenkins_sg.id
  description              = "Jenkins can SSH into App"
}
####S3 Backend####
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-devops-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name = "Terraform State Bucket"
  }
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state_block_public_access" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

####IAM Roles and Policies####
resource "aws_iam_role" "jenkins_role" {
  name = "jenkins_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "jenkins_ecr_attach" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role_policy_attachment" "jenkins_s3_attach" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins-ecr-instance-profile"
  role = aws_iam_role.jenkins_role.name
}

resource "aws_iam_role" "app_role" {
  name = "app_ecr_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "app_ecr_readonly" {
  role       = aws_iam_role.app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "app_profile" {
  name = "app_instance_profile"
  role = aws_iam_role.app_role.name
}

#ECR Repository####
resource "aws_ecr_repository" "app_repository" {
  name = "my-app"

  tags = {
    Name = "App ECR Repository"
  }
  
}
