################################################################################
# CodePipeline
################################################################################

resource "aws_codepipeline" "this" {

  name     = var.application_name
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {

    location = aws_s3_bucket.codepipeline.id
    type     = "S3"

    encryption_key {
      id   = aws_kms_key.this.id
      type = "KMS"
    }
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      run_order        = 1
      output_artifacts = ["SOURCE_ARTIFACT"]
      configuration = {
        RepositoryName       = aws_codecommit_repository.this.repository_name
        BranchName           = "main"
        PollForSourceChanges = true
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "BuildImage"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      run_order        = 2
      input_artifacts  = ["SOURCE_ARTIFACT"]
      output_artifacts = ["BUILD_ARTIFACT"]
      namespace        = "packerBuild"
      configuration = {
        ProjectName = aws_codebuild_project.build.name
        EnvironmentVariables = jsonencode([
          {
            name  = "PACKER_VERSION"
            value = "1.9.4"
            type  = "PLAINTEXT"
          },
          {
            name  = "VARFILE_NAME"
            value = "variables.pkrvars.hcl"
            type  = "PLAINTEXT"
          },
          {
            name  = "MANIFEST_NAME"
            value = "packer-manifest.json"
            type  = "PLAINTEXT"
          },
          {
            name  = "SSM_PARAMETER_PATH"
            value = aws_ssm_parameter.secret.name
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }

  stage {
    name = "ScanImage"
    action {
      name            = "Scan"
      category        = "Invoke"
      owner           = "AWS"
      provider        = "StepFunctions"
      version         = "1"
      run_order       = 3
      input_artifacts = ["BUILD_ARTIFACT"]
      configuration = {
        StateMachineArn = aws_sfn_state_machine.scan_ami.arn
        InputType       = "FilePath"
        Input           = "stepfunction-input.json"
      }
    }
  }

  stage {
    name = "Approve"
    action {
      name      = "Approve"
      category  = "Approval"
      owner     = "AWS"
      provider  = "Manual"
      version   = "1"
      run_order = 4
      configuration = {
        NotificationArn = aws_sns_topic.this.arn
      }
    }
  }

  stage {
    name = "ShareImage"
    action {
      name            = "Share"
      category        = "Invoke"
      owner           = "AWS"
      provider        = "StepFunctions"
      version         = "1"
      run_order       = 5
      input_artifacts = ["BUILD_ARTIFACT"]
      configuration = {
        StateMachineArn = aws_sfn_state_machine.share_ami.arn
        InputType       = "FilePath"
        Input           = "stepfunction-input.json"
      }
    }
  }
}


################################################################################
# IAM Role for CodePipeline
################################################################################

resource "aws_iam_role" "codepipeline" {
  name = format("%s-%s", var.application_name, "codepipeline")

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "codepipeline" {
  statement {
    sid = "s3access"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
      "s3:ListBucket",
    ]

    resources = [aws_s3_bucket.codepipeline.arn, "${aws_s3_bucket.codepipeline.arn}/*"]
  }

  statement {
    sid = "codecommitaccess"
    actions = [
      "codecommit:GetBranch",
      "codecommit:GetCommit",
      "codecommit:UploadArchive",
      "codecommit:GetUploadArchiveStatus",
      "codecommit:CancelUploadArchive"
    ]

    resources = [aws_codecommit_repository.this.arn]
  }

  statement {
    sid = "codebuildaccess"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    resources = [
      aws_codebuild_project.build.arn
    ]
  }

  statement {
    sid = "snsaccess"
    actions = [
      "SNS:Publish"
    ]
    resources = [
      aws_sns_topic.this.arn
    ]
  }

  statement {
    sid = "kmsaccess"
    actions = [
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:Decrypt"
    ]
    resources = [aws_kms_key.this.arn]
  }

  statement {
    sid = "sfnaccess"
    actions = [
      "states:DescribeStateMachine",
      "states:DescribeExecution",
      "states:StartExecution"
    ]
    resources = [
      aws_sfn_state_machine.scan_ami.arn,
      "${replace(aws_sfn_state_machine.scan_ami.arn, "stateMachine", "execution")}:*",
      aws_sfn_state_machine.share_ami.arn,
      "${replace(aws_sfn_state_machine.share_ami.arn, "stateMachine", "execution")}:*"
    ]
  }
}

resource "aws_iam_policy" "codepipeline" {
  name   = "codepipeline"
  policy = data.aws_iam_policy_document.codepipeline.json
}

resource "aws_iam_role_policy_attachment" "codepipeline" {
  role       = aws_iam_role.codepipeline.name
  policy_arn = aws_iam_policy.codepipeline.arn
}
