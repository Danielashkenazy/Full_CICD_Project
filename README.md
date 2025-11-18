# 🚀 Automated Jenkins CI/CD Platform on AWS

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4.svg)](https://www.terraform.io/)
[![Jenkins](https://img.shields.io/badge/Jenkins-LTS-D24939.svg)](https://www.jenkins.io/)
[![AWS](https://img.shields.io/badge/AWS-EC2%20%7C%20ECR-FF9900.svg)](https://aws.amazon.com/)
[![Python](https://img.shields.io/badge/Python-3.10-blue.svg)](https://www.python.org/)
[![Docker](https://img.shields.io/badge/Docker-Containerized-2496ED.svg)](https://www.docker.com/)

## 📖 Overview

A **fully automated Jenkins CI/CD platform** deployed on AWS using Infrastructure as Code (Terraform). This project demonstrates complete DevOps automation by provisioning a self-configuring Jenkins master server, JNLP agent node, and a comprehensive CI/CD pipeline that includes code linting, unit testing, Docker containerization, ECR integration, and automated deployment.

### 🎯 What Makes This Special

- **Zero Manual Configuration**: Jenkins configures itself automatically via Groovy init scripts
- **Complete Automation**: From infrastructure to pipeline, everything is code
- **Production-Ready**: Follows DevOps best practices with proper testing and linting
- **Multi-Node Architecture**: Master-Agent setup for distributed builds
- **AWS Native**: ECR for container registry, IAM for security
- **Repeatable**: Destroy and recreate the entire stack in minutes

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS VPC (us-east-1)                       │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                     Public Subnet                           │ │
│  │                                                             │ │
│  │  ┌───────────────────────────────────────────────────────┐ │ │
│  │  │        Jenkins Master (EC2)                           │ │ │
│  │  │  - Jenkins LTS with auto-configuration                │ │ │
│  │  │  - Groovy init scripts                                │ │ │
│  │  │  - Plugins: Git, Pipeline, Docker, ECR, BlueOcean     │ │ │
│  │  │  - Admin user: admin/Admin123!                        │ │ │
│  │  │  - Port: 8080                                         │ │ │
│  │  └───────────────────────────────────────────────────────┘ │ │
│  │                           │                                 │ │
│  │                           │ JNLP Connection                 │ │
│  │                           ▼                                 │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    Private Subnet                           │ │
│  │                                                             │ │
│  │  ┌───────────────────────────────────────────────────────┐ │ │
│  │  │        App Server / Jenkins Agent (EC2)               │ │ │
│  │  │  - JNLP Agent connects to master                      │ │ │
│  │  │  - Docker for building/deploying                      │ │ │
│  │  │  - AWS CLI for ECR operations                         │ │ │
│  │  │  - Runs application containers                        │ │ │
│  │  └───────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐   │
│  │     ECR      │     │      S3      │     │     IAM      │   │
│  │  (Container  │     │  (Terraform  │     │  (Roles &    │   │
│  │   Registry)  │     │    State)    │     │  Policies)   │   │
│  └──────────────┘     └──────────────┘     └──────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌────────────────────┐
                    │   GitHub (SCM)     │
                    │  - Source code     │
                    │  - Jenkinsfile     │
                    └────────────────────┘
```

## ✨ Key Features

### Infrastructure Automation
- **Modular Terraform**: Separate modules for network, compute, security, IAM
- **VPC Architecture**: Public and private subnets with proper routing
- **Security Groups**: Minimal required access with least privilege
- **IAM Roles**: Proper roles for Jenkins master and app server
- **S3 Backend**: Remote state management with versioning
- **ECR Repository**: Private Docker registry

### Jenkins Automation
- **Auto-Configuration**: Groovy init scripts configure Jenkins on first boot
- **Pre-Installed Plugins**: Git, Pipeline, Docker, ECR, BlueOcean
- **Admin User**: Automatically created (admin/Admin123!)
- **Agent Node**: JNLP agent automatically registered
- **Setup Wizard Disabled**: Production-ready out of the box
- **Jenkins URL**: Automatically configured with private IP

### CI/CD Pipeline
- **Linting**: Flake8 for Python code quality checks
- **Unit Testing**: Pytest with coverage
- **Docker Build**: Multi-stage builds with testing
- **ECR Integration**: Automatic push to Amazon ECR
- **Automated Deployment**: Deploy to app server via agent
- **Health Checks**: Verify deployment success

## 📋 Prerequisites

### Required Tools
- **Terraform**: >= 1.5.0
- **AWS CLI**: Configured with credentials
- **SSH Key Pair**: For EC2 access (optional, for debugging)

### AWS Requirements
- AWS Account with appropriate permissions
- IAM user/role with EC2, VPC, ECR, S3, IAM permissions
- AWS CLI configured: `aws configure`

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/Danielashkenazy/Auto_Jenkins_CICD_Terraform_Deployment.git
cd Auto_Jenkins_CICD_Terraform_Deployment
```

### 2. Configure Variables

Edit `Infra/variables.tf` or create `terraform.tfvars`:

```hcl
aws_region          = "us-east-1"
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"
public_az           = "us-east-1a"
private_az          = "us-east-1b"
instance_type       = "t3.medium"
own_ip              = "YOUR_IP/32"  # For Jenkins access
```

### 3. Deploy Infrastructure

```bash
cd Infra

# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Deploy
terraform apply -auto-approve
```

**Wait 5-10 minutes for Jenkins to fully configure itself.**

### 4. Access Jenkins

```bash
# Get Jenkins URL from Terraform output
terraform output jenkins_url

# Or manually:
# http://<JENKINS_PUBLIC_IP>:8080
```

**Credentials:**
- Username: `admin`
- Password: `Admin123!`

### 5. Create Pipeline

1. Log into Jenkins
2. Create new Pipeline job
3. Point to your GitHub repository
4. Jenkins will automatically detect the `Jenkinsfile`
5. Run the pipeline!

## 📁 Project Structure

```
Auto_Jenkins_CICD_Terraform_Deployment/
├── app/
│   ├── app.py              # Simple Flask application
│   ├── Dockerfile          # Multi-stage Docker build with tests
│   ├── requirements.txt    # Python dependencies
│   └── test_app.py         # Unit tests
│
├── Infra/
│   ├── main.tf             # Root Terraform configuration
│   ├── variables.tf        # Input variables
│   ├── outputs.tf          # Output values
│   └── modules/
│       ├── network/        # VPC, Subnets, IGW, NAT
│       │   ├── main.tf
│       │   ├── output.tf
│       │   └── variable.tf
│       ├── security/       # Security Groups
│       │   ├── main.tf
│       │   ├── output.tf
│       │   └── variables.tf
│       ├── Iam/            # IAM Roles & Policies
│       │   ├── main.tf
│       │   ├── output.tf
│       │   └── variables.tf
│       ├── compute/        # EC2 Instances & User Data
│       │   ├── main.tf
│       │   ├── output.tf
│       │   ├── variables.tf
│       │   ├── jenkins_user_data.sh      # Jenkins bootstrap
│       │   └── app_user_data.sh.tmpl     # Agent bootstrap
│       └── ecr_s3/         # ECR & S3 for state
│           ├── main.tf
│           ├── output.tf
│           └── variables.tf
│
├── jenkins/
│   ├── init.groovy.d/
│   │   ├── 01-basic-security.groovy      # Admin user & auth
│   │   ├── 02-install-plugins.groovy     # Auto-install plugins
│   │   ├── 03-create-agent-node.groovy   # Register JNLP agent
│   │   └── 04-set-url-groovy             # Configure Jenkins URL
│   └── plugins.txt         # Plugin list
│
├── Jenkinsfile             # CI/CD Pipeline definition
└── README.md
```

## 🔧 Application Details

### Flask Application

Simple REST API with two endpoints:

```python
GET  /        # Returns "Hello, Devops!"
POST /echo    # Echoes back JSON payload
```

### Dockerfile

Multi-stage build that:
1. Installs dependencies
2. Copies application code
3. **Runs pytest during build** (fails if tests don't pass)
4. Exposes port 5000
5. Runs Flask application

## 🔄 CI/CD Pipeline Stages

### 1. Checkout
- Clones repository from GitHub
- Uses Jenkins SCM integration

### 2. Prepare Environment
- Retrieves AWS Account ID
- Constructs ECR repository URI
- Sets environment variables

### 3. Lint
- Runs Flake8 on Python code
- Checks code quality and style
- Ignores line length (E501)

### 4. Unit Tests
- Installs pytest and dependencies
- Runs all tests
- Pipeline fails if tests fail

### 5. Build & Push to ECR
- Authenticates with Amazon ECR
- Builds Docker image
- **Tests run inside Docker build**
- Pushes image to ECR with `latest` tag

### 6. Deploy on App Server
- Switches to JNLP agent (label: 'app')
- Authenticates with ECR
- Pulls latest image
- Stops old container
- Runs new container on port 80
- Health check with curl

## 🔐 Security Features

### Network Security
- Jenkins in public subnet (accessible via port 8080)
- App server in private subnet (no direct internet access)
- Security groups limit access to specific ports
- NAT Gateway for private subnet outbound access

### IAM Security
- Separate roles for Jenkins and app server
- Least privilege policies
- ECR push/pull permissions
- S3 access for Terraform state

### Jenkins Security
- Admin user created automatically
- Anonymous access disabled
- Full control for authenticated users
- CSRF protection enabled

## 📊 Monitoring & Troubleshooting

### Check Jenkins Logs

```bash
# SSH to Jenkins master
ssh -i your-key.pem ubuntu@<JENKINS_IP>

# View Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log

# View user-data logs (first boot)
sudo cat /var/log/user-data.log
```

### Check Agent Connection

```bash
# On Jenkins UI
Manage Jenkins → Nodes → app-agent

# Should show "Connected" status
```

### Verify Docker Containers

```bash
# SSH to app server (via bastion or Jenkins master)
docker ps
docker logs myapp
curl http://localhost
```

### Common Issues

#### Jenkins Not Accessible
- Check security group allows your IP on port 8080
- Verify instance is running: `terraform output`
- Check user-data script: `sudo cat /var/log/user-data.log`

#### Agent Not Connecting
- Verify network connectivity between master and agent
- Check JNLP port (50000) in security groups
- Review agent logs in Jenkins UI

#### Pipeline Fails at ECR Push
- Verify IAM role has ECR permissions
- Check AWS CLI is installed: `aws --version`
- Verify ECR repository exists

#### Deployment Fails
- Check Docker is running on app server
- Verify ECR authentication works
- Review application logs: `docker logs myapp`

## 🧪 Testing the Application

### Manual Testing

```bash
# Health check
curl http://<APP_SERVER_IP>

# Echo endpoint
curl -X POST http://<APP_SERVER_IP>/echo \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello, Jenkins!"}'
```

### Automated Testing

The pipeline includes:
- **Linting**: `flake8 app.py --ignore=E501`
- **Unit Tests**: `pytest -q`
- **Docker Build Tests**: Pytest runs during Docker build
- **Health Check**: `curl -f http://localhost`

## 🔄 Making Changes

### Update Application

1. Modify `app/app.py`
2. Update `app/test_app.py` if needed
3. Commit and push to GitHub
4. Jenkins will automatically:
   - Lint the code
   - Run tests
   - Build new Docker image
   - Deploy to app server

### Update Infrastructure

```bash
cd Infra
# Modify Terraform files
terraform plan
terraform apply
```

### Update Jenkins Configuration

Groovy scripts in `jenkins/init.groovy.d/` are executed **only on first boot**. To apply changes:
1. Modify the script
2. Destroy and recreate: `terraform destroy && terraform apply`
3. Or manually apply changes in Jenkins UI

## 🧹 Cleanup

### Destroy Infrastructure

```bash
cd Infra
terraform destroy -auto-approve
```

**Note**: This will delete:
- All EC2 instances
- VPC and networking
- ECR repository (images will be deleted)
- S3 bucket (if empty)

### Manual Cleanup

If Terraform destroy fails:
1. Manually delete running EC2 instances
2. Delete security groups
3. Delete VPC
4. Run `terraform destroy` again

## 📈 Performance & Scaling

### Scaling Considerations

**Current Setup (Dev/Test):**
- Jenkins Master: t3.medium (2 vCPU, 4 GB RAM)
- App Server: t3.medium (2 vCPU, 4 GB RAM)

**Production Recommendations:**
- Jenkins Master: t3.large or t3.xlarge
- Add more agent nodes (2-5 agents)
- Use Auto Scaling Group for agents
- Enable Jenkins backup to S3
- Use RDS for job history persistence

### Cost Optimization

- Use Spot Instances for agent nodes
- Stop instances when not in use
- Use smaller instance types for development
- Enable ECR lifecycle policies to delete old images

## 📝 TODO / Roadmap

- [ ] Add SSL/TLS for Jenkins (HTTPS)
- [ ] Implement Jenkins backup to S3
- [ ] Add more test stages (integration tests)
- [ ] Implement blue-green deployment
- [ ] Add Slack/Email notifications
- [ ] Create Auto Scaling Group for agents
- [ ] Add SonarQube for code quality
- [ ] Implement Trivy for container scanning
- [ ] Add Prometheus monitoring
- [ ] Create CloudWatch dashboards

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a Pull Request

## 📄 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

- **Jenkins Community** for the amazing CI/CD platform
- **HashiCorp** for Terraform
- **AWS** for cloud infrastructure
- **Python** and **Flask** communities

## 📞 Contact & Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/Danielashkenazy/Auto_Jenkins_CICD_Terraform_Deployment/issues)
- **Pull Requests**: Contributions welcome!

## 🌟 Show Your Support

If you find this project useful:
- ⭐ Star the repository
- 🍴 Fork for your own projects
- 📢 Share with others
- 💬 Provide feedback

---

**Built with ❤️ for DevOps automation enthusiasts**

*"Automate everything, touch nothing!"* 🤖
