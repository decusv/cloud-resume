import {
  to = aws_s3_bucket.website-bucket
  id = "tomas-riabovas-resume-bucket"
}

import {
  to = aws_s3_bucket_cors_configuration.website-bucket
  id = "tomas-riabovas-resume-bucket,160885289344"
}

import {
  to = aws_s3_bucket_public_access_block.website-bucket
  id = "tomas-riabovas-resume-bucket"
}

import {
  to = aws_cloudfront_distribution.website
  id = "E2KD1KTCP8ICIU"
}

import {
  to = aws_cloudfront_origin_access_control.website
  id = "E1F3DJXH8RKIX3"
}
import {
  to = aws_apigatewayv2_api.website
  id = "8kvo99fqbb"
}

import {
  to = aws_apigatewayv2_route.put_visitor
  id = "8kvo99fqbb/3hjkn7g"
}

import {
  to = aws_apigatewayv2_integration.put_visitor_integration
  id = "8kvo99fqbb/f49oi3r"
}

import {
  to = aws_apigatewayv2_stage.default
  id = "8kvo99fqbb/$default"
}

import {
  to = aws_lambda_function.visitor_counter
  id = "cloud-resume-visitor-counter"
}

import {
  to = aws_lambda_function.reset-unique-visitors
  id = "cloud-resume-reset-unique-visitors"
}

import {
  to = aws_iam_role.lambda_role
  id = "lambda-function-resume-counter"
}

import {
  to = aws_cloudwatch_event_rule.monthly_reset
  id = "default/monthly-trigger"
}

import {
  to = aws_dynamodb_table.visitor_count
  id = "cloud-resume-visitor-count"
}

import {
  to = aws_acm_certificate.website
  id = "arn:aws:acm:us-east-1:160885289344:certificate/1a40a39e-37b4-4bf6-a72c-089263cd1340"
}