aws_region   = "us-east-1"
project_name = "vastraco"
environment  = "production"

# VPC
vpc_cidr                 = "10.0.0.0/16"
public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24"]
private_app_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
private_db_subnet_cidrs  = ["10.0.20.0/24", "10.0.21.0/24"]

# EKS - cost-optimised for 4-day demo
kubernetes_version = "1.31"
node_instance_type = "t3.medium"
node_desired_size  = 2
node_min_size      = 1
node_max_size      = 3

# RDS - cost-optimised
db_name           = "vastraco"
db_username       = "vastraco_admin"
db_instance_class = "db.t3.micro"
db_engine_version = "16.14"

# Domain
domain_name = "vastraco.online"

# Alerts
alert_email = "harshithasrinivask@gmail.com"
