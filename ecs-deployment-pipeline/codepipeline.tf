################################################################################
# CodePipeline
################################################################################

resource "aws_codepipeline" "this" {

  name     = var.application_name
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {

    location = aws_s3_bucket.artifacts.id
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

    action {
      name             = "Static"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      run_order        = 1
      output_artifacts = ["STATIC_ARTIFACT"]
      configuration = {
        S3Bucket             = aws_s3_bucket.static.id
        S3ObjectKey          = aws_s3_object.static.key
        PollForSourceChanges = false
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
      configuration = {
        ProjectName = aws_codebuild_project.build.name
        EnvironmentVariables = jsonencode([
          {
            name  = "AWS_ACCOUNT_ID"
            value = data.aws_caller_identity.current.id
            type  = "PLAINTEXT"
          },
          {
            name  = "AWS_REGION"
            value = data.aws_region.current.name
            type  = "PLAINTEXT"
          },
          {
            name  = "REPOSITORY_NAME"
            value = aws_ecr_repository.this.name
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }


  stage {
    name = "DeployImage"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      version         = "1"
      run_order       = 3
      input_artifacts = ["STATIC_ARTIFACT", "BUILD_ARTIFACT"]

      configuration = {
        ApplicationName                = aws_codedeploy_app.this.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.this.deployment_group_name
        TaskDefinitionTemplateArtifact = "STATIC_ARTIFACT"
        TaskDefinitionTemplatePath     = "taskdef.json"
        AppSpecTemplateArtifact        = "STATIC_ARTIFACT"
        AppSpecTemplatePath            = "appspec.yaml"
        Image1ArtifactName             = "BUILD_ARTIFACT"
        Image1ContainerName            = "IMAGE1_NAME"
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

    resources = [
      aws_s3_bucket.artifacts.arn,
      "${aws_s3_bucket.artifacts.arn}/*",
      aws_s3_bucket.static.arn,
    "${aws_s3_bucket.static.arn}/*"]
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
    sid = "codedeploydaccess"
    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplicationRevision",
      "codedeploy:GetApplication",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision",
      "ecs:RegisterTaskDefinition"
    ]
    resources = [
      aws_codedeploy_app.this.arn,
      aws_codedeploy_deployment_group.this.arn,
      format("arn:aws:codedeploy:%s:%s:deploymentconfig:*",data.aws_region.current.name, data.aws_caller_identity.current.account_id),
      format("arn:aws:ecs:%s:%s:task-definition/fargate-task-definition:*",data.aws_region.current.name, data.aws_caller_identity.current.account_id)
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
    sid = "iamaccess"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      aws_iam_role.ecs_execution.arn
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
}

resource "aws_iam_policy" "codepipeline" {
  name   = "codepipeline"
  policy = data.aws_iam_policy_document.codepipeline.json
}

resource "aws_iam_role_policy_attachment" "codepipeline" {
  role       = aws_iam_role.codepipeline.name
  policy_arn = aws_iam_policy.codepipeline.arn
}
