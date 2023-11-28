resource "aws_codebuild_project" "lint_project" {
  name = "lint-project"
  source {
    type      = "CODEPIPELINE"
    buildspec = file("../buildspec/lint.yml")
  }
  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:4.0"
    type         = "LINUX_CONTAINER"
  }

  cache {
    type = "NO_CACHE"
  }

  service_role = local.codebuild_role_arn
}

resource "aws_codebuild_project" "build_project" {
  name = "build-project"
  source {
    type      = "CODEPIPELINE"
    buildspec = file("../buildspec/build.yml")
  }
  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:4.0"
    type         = "LINUX_CONTAINER"
  }

  cache {
    type = "NO_CACHE"
  }

  service_role = local.codebuild_role_arn
}

resource "aws_codedeploy_app" "example_deployment_app" {
  name             = "my_deployment_app"
  compute_platform = "Server"
}

resource "aws_codedeploy_deployment_group" "example_codedeploy_group" {
  app_name              = aws_codedeploy_app.example_deployment_app.name
  deployment_group_name = "my_deployment_group"
  service_role_arn      = local.codedeploy_role_arn
  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = aws_instance.cicd_instance.tags.Name
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}

resource "aws_codepipeline" "example_pipeline" {
  depends_on = [aws_instance.cicd_instance]
  name       = "example-pipeline"
  role_arn   = local.codepipeline_role_arn

  artifact_store {
    location = local.artifact_bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "SourceAction"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["SourceOutput"]

      configuration = {
        RepositoryName = local.repository_name
        BranchName     = "master"
      }
    }
  }

  #  stage {
  #    name = "Lint"
  #
  #    action {
  #      name            = "LintAction"
  #      category        = "Build"
  #      owner           = "AWS"
  #      provider        = "CodeBuild"
  #      version         = "1"
  #      input_artifacts = ["SourceOutput"]
  #
  #      configuration = {
  #        ProjectName = aws_codebuild_project.lint_project.name
  #      }
  #    }
  #  }
  #
  #  stage {
  #    name = "Build"
  #
  #    action {
  #      name            = "BuildAction"
  #      category        = "Build"
  #      owner           = "AWS"
  #      provider        = "CodeBuild"
  #      version         = "1"
  #      input_artifacts = ["SourceOutput"]
  #
  #      configuration = {
  #        ProjectName = aws_codebuild_project.build_project.name
  #      }
  #    }
  #  }

  stage {
    name = "Deploy"

    action {
      name            = "DeployAction"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["SourceOutput"]

      configuration = {
        ApplicationName     = aws_codedeploy_app.example_deployment_app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.example_codedeploy_group.deployment_group_name
      }
    }
  }
}
