terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = var.region_eu
  profile = var.aws_profile
}

provider "aws" {
  alias   = "us-east-1"
  region  = var.region_us
  profile = var.aws_profile
}

# Create an Origin Access Control
resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "${var.bucket_name}.s3.${var.region_eu}.amazonaws.com"
  origin_access_control_origin_type = "s3"     # Specify the origin type (e.g., S3)
  signing_behavior                  = "always" # Choose whether to sign requests
  signing_protocol                  = "sigv4"  # Choose the signing protocol
}

# S3 bucket for website files
resource "aws_s3_bucket" "website-bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_cors_configuration" "website-bucket" {
  bucket = aws_s3_bucket.website-bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_public_access_block" "website-bucket" {
  bucket = aws_s3_bucket.website-bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  default_root_object = "index.html"
  is_ipv6_enabled     = true

  origin {
    domain_name              = aws_s3_bucket.website-bucket.bucket_regional_domain_name
    origin_id                = var.cloudfront_s3_origin_name
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = var.cloudfront_s3_origin_name
    viewer_protocol_policy = "allow-all"
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  aliases = [var.domain_name]

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.website.arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }
}

resource "aws_apigatewayv2_api" "website" {
  name          = "visitors"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = var.api_gateway_cors_allowed_origins
    allow_methods = var.api_gateway_cors_allowed_methods
    allow_headers = var.api_gateway_cors_allowed_headers
  }
}

resource "aws_apigatewayv2_route" "put_visitor" {
  api_id    = aws_apigatewayv2_api.website.id
  route_key = "PUT /cloud-resume-visitor-counter"
  target    = "integrations/${aws_apigatewayv2_integration.put_visitor_integration.id}"
}

resource "aws_apigatewayv2_integration" "put_visitor_integration" {
  api_id                 = aws_apigatewayv2_api.website.id
  integration_type       = "AWS_PROXY"                                                                   # Change to your integration type
  integration_uri        = "arn:aws:lambda:eu-west-2:${var.aws_account_id}:function:${aws_lambda_function.visitor_counter.function_name}"
  integration_method     = "PUT"
  payload_format_version = "2.0" # Change to your backend method
}

# CORS Configuration
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.website.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    data_trace_enabled       = false
    detailed_metrics_enabled = false
    throttling_burst_limit   = 200
    throttling_rate_limit    = 100
  }
}

# Lambda functions
resource "aws_lambda_function" "visitor_counter" {
  filename      = "AWS/lambda/update_visitors/visitor-counter.zip"
  function_name = "visitor-counter"
  role          = aws_iam_role.lambda_role.arn
  handler       = "visitor-counter.lambda_handler"
  runtime       = "python3.10"
}

resource "aws_lambda_function" "reset-unique-visitors" {
  filename      = "AWS/lambda/visitor_reset/reset-unique-visitors.zip" # You'll need to create this
  function_name = "reset-unique-visitors"
  role          = aws_iam_role.lambda_role.arn
  handler       = "reset-unique-visitors.lambda_handler"
  runtime       = "python3.10"
}

# IAM role for Lambda functions
resource "aws_iam_role" "lambda_role" {
  name                = "lambda-function-resume-counter"
  managed_policy_arns = ["arn:aws:iam::${var.aws_account_id}:policy/service-role/AWSLambdaBasicExecutionRole-efc1de47-7a78-4d0a-b852-04df3ce8d1ee", "arn:aws:iam::${var.aws_account_id}:policy/limited-lambda-function-dynamodb-visitor-table"]

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

# CloudWatch Event (EventBridge) rule for monthly IP hash reset
resource "aws_cloudwatch_event_rule" "monthly_reset" {
  name                = "monthly-trigger"
  description         = "Triggers the IP hash reset Lambda function monthly"
  schedule_expression = "cron(0 0 1 * ? *)"
}

# ACM Certificate in us-east-1
resource "aws_acm_certificate" "website" {
  provider          = aws.us-east-1
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_dynamodb_table" "visitor_count" {
  name         = "cloud-resume-visitor-count" # Name of the table
  billing_mode = "PAY_PER_REQUEST"            # Billing mode (on-demand)

  attribute {
    name = "id" # Primary key attribute
    type = "S"  # String type
  }

  hash_key = "id" # Specify the primary key
}

resource "aws_lambda_permission" "allow_apigateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.website.execution_arn}/*/*"
}

