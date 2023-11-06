##################################################
# Step-Function Part 1: Scan AMI
##################################################

resource "aws_sfn_state_machine" "scan_ami" {
  name     = format("%s-%s", var.application_name, "scan-ami")
  role_arn = aws_iam_role.sfn.arn

  definition = templatefile("${path.module}/step-functions/scan-ami.json", {
    instance_type             = "t2.micro"
    security_group_id         = aws_security_group.scan_ami.id
    subnet_id                 = data.aws_subnets.default.ids[0]
    iam_instance_profile_name = aws_iam_instance_profile.scan_ami.name
    sns_topic_arn             = aws_sns_topic.this.arn
    step_function_part_2      = aws_sfn_state_machine.export_findings.arn
    eventbridge_rule_name     = format("%s-%s", var.application_name, "ami-scan-successful")
    eventbrdige_role_arn      = aws_iam_role.eventbridge.arn
  })
}

##################################################
# Step-Function Part 2: Store Findings
##################################################

resource "aws_sfn_state_machine" "export_findings" {
  name     = format("%s-%s", var.application_name, "export-findings")
  role_arn = aws_iam_role.sfn.arn

  definition = templatefile("${path.module}/step-functions/export-findings.json", {
    lambda_function_name  = aws_lambda_function.export_findings.function_name
    sns_topic_arn         = aws_sns_topic.this.arn
    eventbridge_rule_name = format("%s-%s", var.application_name, "ami-scan-successful")
  })
}


################################################################################
# IAM Role for Step-Function
################################################################################

resource "aws_iam_role" "sfn" {
  name = format("%s-%s", var.application_name, "sfn")

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "sfn" {
  statement {
    sid = "ec2"
    actions = [
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "ec2:CreateTags"
    ]

    resources = ["*"]
  }

  statement {
    sid = "sns"
    actions = [
      "sns:Publish"
    ]

    resources = [aws_sns_topic.this.arn]
  }

  statement {
    sid = "eventBridge"
    actions = [
      "events:PutRule",
      "events:PutTargets",
      "events:DeleteRule",
      "events:RemoveTargets"
    ]
    resources = ["*"]
  }

  statement {
    sid = "lambda"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [aws_lambda_function.export_findings.arn]
  }

  statement {
    sid = "iam"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      aws_iam_role.scan_ami.arn,
      aws_iam_role.eventbridge.arn
    ]
  }
}



resource "aws_iam_policy" "sfn" {
  name   = "sfn"
  policy = data.aws_iam_policy_document.sfn.json
}

resource "aws_iam_role_policy_attachment" "sfn" {
  role       = aws_iam_role.sfn.name
  policy_arn = aws_iam_policy.sfn.arn
}


################################################################################
# EC2 Instance Profile for Scan Instance
################################################################################

resource "aws_iam_role" "scan_ami" {
  name = format("%s-%s", var.application_name, "scan-ami")

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_instance_profile" "scan_ami" {
  name = "${aws_iam_role.scan_ami.name}-ip"
  role = aws_iam_role.scan_ami.name
}

resource "aws_iam_role_policy_attachment" "scan_ami" {
  role       = aws_iam_role.scan_ami.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


################################################################################
# IAM Role for EventBridge
################################################################################

resource "aws_iam_role" "eventbridge" {
  name = format("%s-%s", var.application_name, "eventbridge")

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "eventbridge" {

  statement {
    sid = "eventBridge"
    actions = [
      "states:StartExecution"
    ]
    resources = [aws_sfn_state_machine.export_findings.arn]
  }

  statement {
    sid = "iam"
    actions = [
      "iam:PassRole"
    ]
    resources = [aws_iam_role.sfn.arn]
  }
}



resource "aws_iam_policy" "eventbridge" {
  name   = format("%s-%s", var.application_name, "eventbridge")
  policy = data.aws_iam_policy_document.eventbridge.json
}

resource "aws_iam_role_policy_attachment" "eventbridge" {
  role       = aws_iam_role.eventbridge.name
  policy_arn = aws_iam_policy.eventbridge.arn
}

################################################################################
# Client Security Group
################################################################################

resource "aws_security_group" "scan_ami" {
  name   = format("%s-%s", var.application_name, "scan-ami")
  vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group_rule" "egress" {
  security_group_id = aws_security_group.scan_ami.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["0.0.0.0/0"]
}