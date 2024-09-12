################################################################################
# OpenSearch Domain
################################################################################

resource "aws_opensearch_domain" "this" {
  domain_name    = var.application_name
  engine_version = "OpenSearch_2.15"

  cluster_config {
    instance_type                 = "r6g.large.search"
    multi_az_with_standby_enabled = false
    instance_count                = 1
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = 100
  }

  encrypt_at_rest {
    enabled    = true
    kms_key_id = aws_kms_key.this.id
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-PFS-2023-10"
  }

  advanced_security_options {
    enabled                        = true
    anonymous_auth_enabled         = false
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = "admin"
      master_user_password = random_password.opensearch.result
    }
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch.arn
    enabled                  = true
    log_type                 = "INDEX_SLOW_LOGS"
  }
}

################################################################################
# OpenSearch Domain Policy
################################################################################

data "aws_iam_policy_document" "opensearch_access_policy" {
  statement {
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.zeek.arn,
        "arn:aws:iam::843934227598:role/tRSuperAdminCAA"
      ]
    }

    actions   = ["es:*"]
    resources = ["${aws_opensearch_domain.this.arn}/*"]
  }

  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["es:*"]
    resources = ["${aws_opensearch_domain.this.arn}/*"]

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = ["${chomp(data.http.this.response_body)}/32"]
    }
  }
}

resource "aws_opensearch_domain_policy" "this" {
  domain_name     = aws_opensearch_domain.this.domain_name
  access_policies = data.aws_iam_policy_document.opensearch_access_policy.json
}

################################################################################
# Cloudwatch Log Group
################################################################################

resource "aws_cloudwatch_log_group" "opensearch" {
  name = "/aws/opensearch/${var.application_name}"

  retention_in_days = 30
}

data "aws_iam_policy_document" "opensearch_cloudwatch" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["es.amazonaws.com"]
    }

    actions = [
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch",
      "logs:CreateLogStream",
    ]

    resources = ["${aws_cloudwatch_log_group.opensearch.arn}:*"]
  }
}

resource "aws_cloudwatch_log_resource_policy" "opensearch" {
  policy_name     = "opensearch"
  policy_document = data.aws_iam_policy_document.opensearch_cloudwatch.json
}

################################################################################
# OpenSearch Logstash Writer Role for Zeek
################################################################################

resource "opensearch_role" "this" {
  role_name   = "zeek_logs_writer"
  description = "Zeek Logs writer role"

  cluster_permissions = [
    "cluster_monitor",
    "cluster_composite_ops",
    "indices:admin/template/get",
    "indices:admin/template/put",
    "cluster:admin/ingest/pipeline/put",
    "cluster:admin/ingest/pipeline/get",
  ]

  index_permissions {
    index_patterns  = ["zeek-*"]
    allowed_actions = ["crud", "create_index"]
  }
}

resource "opensearch_roles_mapping" "this" {
  role_name   = "zeek_logs_writer"
  description = "Mapping AWS IAM role to ES zeek role"
  backend_roles = [
    aws_iam_role.zeek.arn
  ]
}
