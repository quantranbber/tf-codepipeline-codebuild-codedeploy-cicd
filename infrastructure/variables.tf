data "aws_caller_identity" "current" {}

locals {
  account_id            = data.aws_caller_identity.current.account_id
  artifact_bucket       = "agw-quantv-ws"
  codebuild_role_arn    = join("", ["arn:aws:iam::", local.account_id, ":role/service-role/codebuild-test-service-role"])
  codepipeline_role_arn = join("", ["arn:aws:iam::", local.account_id, ":role/service-role/AWSCodePipelineServiceRole-ap-southeast-1-test"])
  codedeploy_role_arn   = join("", ["arn:aws:iam::", local.account_id, ":role/my-codedeploy-role"])
  repository_name       = "zzz"
}