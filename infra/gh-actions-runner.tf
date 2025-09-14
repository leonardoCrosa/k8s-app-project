# This is the config for a Self Hosted Runner in AWS

# Security Group
resource "aws_security_group" "runner" {
  name        = "gha-eks-runner-sg"
  description = "Self-hosted GH runner egress"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Permissions so the runner can assume the role
data "aws_iam_policy_document" "assume_ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Runner IAM Role
resource "aws_iam_role" "runner" {
  name               = "gha-eks-runner-role"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
}

# Attachment to IAM Policy that allows access to the instance via SSM
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.runner.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Policy Doc + Policy that allows runner to gather github pat on bootsrap from SSM Parameter store. This lets the runner register to github
data "aws_iam_policy_document" "ssm_param_read" {
  statement {
    actions   = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = ["arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/gha/github-pat"]
  }
}

resource "aws_iam_policy" "ssm_param_read" {
  name   = "gha-eks-runner-ssm-param-read"
  policy = data.aws_iam_policy_document.ssm_param_read.json
}

# Attaches the policy to Runer IAM Role
resource "aws_iam_role_policy_attachment" "ssm_param_read_attach" {
  role       = aws_iam_role.runner.name
  policy_arn = aws_iam_policy.ssm_param_read.arn
}

# Assigns role to runner instance
resource "aws_iam_instance_profile" "runner" {
  name = "gha-eks-runner-profile"
  role = aws_iam_role.runner.name
}

# Get latest AMI from public parameter
data "aws_ssm_parameter" "al2023_std" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

# Randomize runner name
locals {
  runner_name = "gha-eks-runner-${random_id.suffix.hex}"
}
resource "random_id" "suffix" { byte_length = 3 }

# EC2 Instance for the Runner
resource "aws_instance" "runner" {
  ami                    = data.aws_ssm_parameter.al2023_std.value
  instance_type          = "t3.small"
  subnet_id              = module.vpc.private_subnets[0] # I chose the 1st private subnet
  iam_instance_profile   = aws_iam_instance_profile.runner.name
  vpc_security_group_ids = [aws_security_group.runner.id]
  user_data = templatefile("${path.module}/../scripts/runner-userdata.sh.tftpl", {
    # Passing locals and variables from terraform to the runners' user_data
    repo_owner    = "leonardocrosa"
    repo_name     = "k8s-app-project"
    runner_labels = "sh,eks,private" # Labels help match the github actions to the desired runner.
    runner_name   = local.runner_name
    region        = var.region
  })

  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}
