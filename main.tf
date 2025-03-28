provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Main VPC"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "Internet Gateway"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "Private Subnet"
  }
}

resource "aws_sqs_queue" "event_queue" {
  name = "event_queue"

  tags = {
    Environment = "Production"
  }
}

resource "aws_eks_cluster" "k8s_source" {
  name     = "k8s_source"
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = [aws_subnet.private_subnet.id]
  }

  tags = {
    Environment = "Production"
  }
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs_cluster"

  tags = {
    Environment = "Production"
  }
}

resource "aws_ecs_service" "worker" {
  count           = 3
  name            = "worker${count.index + 1}"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.private_subnet.id]
    assign_public_ip = false
  }

  tags = {
    Environment = "Production"
  }
}

resource "aws_s3_bucket" "events_store" {
  bucket = "events-store"

  tags = {
    Environment = "Production"
  }
}

resource "aws_redshift_cluster" "analytics" {
  cluster_identifier = "analytics-cluster"
  node_type          = "dc2.large"
  number_of_nodes    = 1
  master_username    = "admin"
  master_password    = "YourPassword123"

  tags = {
    Environment = "Production"
  }
}

resource "aws_kms_key" "encryption_key" {
  description = "KMS encryption key for data at rest"

  tags = {
    Environment = "Production"
  }
}

resource "aws_iam_role" "iam_role" {
  name = "iam_role"

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
    Environment = "Production"
  }
}

resource "aws_iam_role_policy_attachment" "eks_policy" {
  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "s3_policy" {
  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "redshift_policy" {
  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRedshiftFullAccess"
}

resource "aws_iam_role_policy_attachment" "sqs_policy" {
  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_role_policy_attachment" "kms_policy" {
  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSKeyManagementServicePowerUser"
}