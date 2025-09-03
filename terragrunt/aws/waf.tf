# AWS WAF v2 configuration for CloudFront protection
# Must be in us-east-1 region for CloudFront

resource "aws_wafv2_web_acl" "cloudfront_waf" {
  provider = aws.us-east-1
  name     = "ucdg-cloudfront-waf-${var.env}"
  description = "WAF for UCDG CloudFront distribution with core security rules and rate limiting"
  scope    = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # AWS Core Rule Set - blocks common attacks
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # AWS Known Bad Inputs Rule Set
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputsRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # AWS IP Reputation Rule Set - blocks known bad IPs
  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "IpReputationListMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rate limiting rule - 400 requests per 60 seconds per IP (6.7 requests/sec)
  rule {
    name     = "RateLimitRule"
    priority = 4

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit                   = 400
        aggregate_key_type      = "IP"
        evaluation_window_sec   = 60
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRuleMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "UCDGCloudFrontWAF"
    sampled_requests_enabled   = true
  }

  tags = {
    CostCentre = var.billing_code
    Terraform  = "true"
  }
}

# Output the WAF ACL ARN for use in the module
output "waf_acl_arn" {
  description = "The ARN of the WAF ACL for CloudFront"
  value       = aws_wafv2_web_acl.cloudfront_waf.arn
}