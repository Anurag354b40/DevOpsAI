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

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-cluster"
  tags = {
    Name = "ECS Cluster"
  }
}

resource "aws_ecs_service" "worker1" {
  name            = "worker1"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  desired_count   = 1
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.worker1.arn
  network_configuration {
    subnets = [aws_subnet.private.id]
  }
  tags = {
    Name = "Worker 1"
  }
}

resource "aws_ecs_service" "worker2" {
  name            = "worker2"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  desired_count   = 1
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.worker2.arn
  network_configuration {
    subnets = [aws_subnet.private.id]
  }
  tags = {
    Name = "Worker 2"
  }
}

resource "aws_ecs_service" "worker3" {
  name            = "worker3"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  desired_count   = 1
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.worker3.arn
  network_configuration {
    subnets = [aws_subnet.private.id]
  }
  tags = {
    Name = "Worker 3"
  }
}

resource "aws_s3_bucket" "events_store" {
  bucket = "events-store-bucket"
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
  tags = {
    Name = "Analytics"
  }
}

resource "aws_sqs_queue" "event_queue" {
  name = "event-queue"
  tags = {
    Name = "Event Queue"
  }
}

resource "aws_kms_key" "encryption_key" {
  description = "Encryption key for data at rest"
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
      }
    ]
  })

  tags = {
    Name = "IAM Role"
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