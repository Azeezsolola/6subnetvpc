#=======Enabling Guard duty
resource "aws_guardduty_detector" "MyDetector" {
  enable = true
}

#=======Enabling the following logs so that they can accessed/monitored  by guard duty
resource "aws_guardduty_detector_feature" "eks_protection" {
  detector_id = aws_guardduty_detector.MyDetector.id
  name        = "EKS_AUDIT_LOGS"
  status      = "ENABLED"
}

resource "aws_guardduty_detector_feature" "ebs" {
  detector_id = aws_guardduty_detector.MyDetector.id
  name        = "EBS_MALWARE_PROTECTION"
  status      = "ENABLED"
}


resource "aws_guardduty_detector_feature" "rds" {
  detector_id = aws_guardduty_detector.MyDetector.id
  name        = "RDS_LOGIN_EVENTS"
  status      = "ENABLED"
}


resource "aws_guardduty_detector_feature" "s3" {
  detector_id = aws_guardduty_detector.MyDetector.id
  name        = "S3_DATA_EVENTS"
  status      = "ENABLED"
}

#===========Creating sns topic for guard duty to send out it findings to the subscribers 
resource "aws_sns_topic" "guardduty_alerts" {
  name = "guardduty-alerts"
}

#---------------Creating subscribers for for the guard duuty alerts -------------------------------------
resource "aws_sns_topic_subscription" "subscription8" {
  topic_arn = aws_sns_topic.guardduty_alerts.arn
  protocol  = "email"
  endpoint  = "azeezsolola@gmail.com"   
}

resource "aws_sns_topic_subscription" "subscription9" {
  topic_arn = aws_sns_topic.guardduty_alerts.arn
  protocol  = "email"
  endpoint  = "michael.ojejinmi@stackitsolutions.com"   
}



#---------------Creating cloudwatch event rule to capture gaurd duty findings ------------------------------
#Create a CloudWatch Event rule to capture GuardDuty findings
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "guardduty-findings"
  description = "Capture all GuardDuty findings"
  event_pattern = <<EOF
{
  "source": ["aws.guardduty"]
}
EOF
}


#-----------------sneding guard duty findings to targets(people  who have subscribed to the sns topic)-------------------------------------------
resource "aws_cloudwatch_event_target" "sns_target" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.guardduty_alerts.arn
}



# Allow CloudWatch to publish to SNS
resource "aws_sns_topic_policy" "guardduty_sns_policy" {
  arn    = aws_sns_topic.guardduty_alerts.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action = "sns:Publish"
        Resource = aws_sns_topic.guardduty_alerts.arn
      }
    ]
  })
}




#---------------Retrieving the iam policy for lamda function role --------------
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


#-------------Creating the role to be assumed by lambda ----------------
resource "aws_iam_role" "lambda_role" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}


#-----------Creating an inline policy to be attached to the lamda role. This gives lambda the permmission to do certain things ------------
resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_guardduty_policy"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:ModifyInstanceAttribute",
          "ec2:DescribeVolumes",
          "ec2:CreateSnapshot",
          "ec2:DescribeSecurityGroups",
          "ec2:ModifyInstanceAttribute",
          "ec2:DescribeVolumes",
          "ec2:StopInstances"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "autoscaling:DetachInstances",
          "autoscaling:SetInstanceProtection"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "sns:Publish"
        ],
        Resource = aws_sns_topic.guardduty_alerts.id

      }
    ]
  })
}
#--------------creating lambda function to be triggered by the event bridge ------------------------------------
resource "aws_lambda_function" "quarantine" {
  filename         = "lambdafunction.zip"        #contains my python files
  function_name    = "guardduty-remediation-process"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambdafucntion.lambda_handler"
  runtime          = "python3.10"
  timeout          = 300
  memory_size      = 256
  source_code_hash = filebase64sha256("lambdafunction.zip")
}

#---------------------------Creating even bridge target to trigger the lambda function ---------------------------
resource "aws_cloudwatch_event_target" "guardduty_lambda" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "GuardDutyQuarantineLambda"
  arn       = aws_lambda_function.quarantine.arn
}


#------Giving event bridge permission to trigger lambda function --------------------------------------------
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.quarantine.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_findings.arn
}



