provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Main VPC"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Internet Gateway"
  }
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "Private Subnet"
  }
}

resource "aws_sqs_queue" "event_queue" {
  name = "event-queue"

  tags = {
    Name = "Event Queue"
  }
}

resource "aws_eks_cluster" "k8s_source" {
  name     = "k8s-source"
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = [aws_subnet.private.id]
  }

  tags = {
    Name = "K8s Source"
  }
}

resource "aws_ecs_cluster" "workers" {
  name = "ecs-workers"

  tags = {
    Name = "ECS Workers"
  }
}

resource "aws_s3_bucket" "events_store" {
  bucket = "events-store"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.encryption_key.arn
      }
    }
  }

  tags = {
    Name = "Events Store"
  }
}

resource "aws_redshift_cluster" "analytics" {
  cluster_identifier = "analytics-cluster"
  node_type          = "dc2.large"
  master_username    = "admin"
  master_password    = "YourPassword123"
  cluster_type       = "single-node"
  encrypted          = true
  kms_key_id         = aws_kms_key.encryption_key.arn

  tags = {
    Name = "Analytics"
  }
}

resource "aws_kms_key" "encryption_key" {
  description = "KMS encryption key for data at rest"

  tags = {
    Name = "Encryption Key"
  }
}

resource "aws_iam_role" "iam_role" {
  name = "iam-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "IAM Role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_role_policy" {
  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "s3_access_policy" {
  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "redshift_access_policy" {
  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRedshiftFullAccess"
}

resource "aws_iam_role_policy_attachment" "sqs_access_policy" {
  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_role_policy_attachment" "kms_access_policy" {
  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSKeyManagementServicePowerUser"
}