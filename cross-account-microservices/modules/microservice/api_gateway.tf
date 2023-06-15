################################################################################
# REST API
################################################################################

resource "aws_api_gateway_rest_api" "this" {
  name = format("%s-%s", var.application_name, var.microservice_name)

  body = templatefile(var.api_gateway_definition_template,
    {
      application_name  = var.application_name
      microservice_name = var.microservice_name
      order_options     = yamlencode({ "enum" : "${var.microservice_order_options}" })
      get_orders_arn    = aws_lambda_function.this["get-orders"].arn
      post_order_arn    = aws_lambda_function.this["post-order"].arn
      get_order_arn     = aws_lambda_function.this["get-order"].arn
    }
  )

  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = [local.api_gateway_vpc_endpoint_id]
  }
}


################################################################################
# REST API Policy
################################################################################

resource "aws_api_gateway_rest_api_policy" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  policy = data.aws_iam_policy_document.vpce_access.json
}

data "aws_iam_policy_document" "vpce_access" {
  statement {

    actions = [
      "execute-api:Invoke",
    ]
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      "${aws_api_gateway_rest_api.this.execution_arn}/*/*/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:sourceVpce"
      values   = [local.api_gateway_vpc_endpoint_id]
    }
  }
}


################################################################################
# Create Deployment and API Gateway Stage
################################################################################

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_api_gateway_rest_api_policy.this]
}

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = "v1"
}


################################################################################
# REST API Domain Name
################################################################################

resource "aws_api_gateway_domain_name" "this" {
  domain_name              = var.domain_name
  regional_certificate_arn = aws_acm_certificate.this.arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}


resource "aws_api_gateway_base_path_mapping" "this" {
  api_id      = aws_api_gateway_rest_api.this.id
  domain_name = aws_api_gateway_domain_name.this.domain_name

  stage_name = aws_api_gateway_stage.this.stage_name
  base_path  = aws_api_gateway_stage.this.stage_name
}
