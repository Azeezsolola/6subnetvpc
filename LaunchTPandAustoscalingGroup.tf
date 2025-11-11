#------------------- Pulling database information from ssm ---------------------------------------
data "aws_ssm_parameter" "dbusername" {
  name = "Db_username"
}


data "aws_ssm_parameter" "dbendpoint" {
  name = "dbendpoint"
}

data "aws_ssm_parameter" "dbpassword" {
  name = "dbpassword"
}

#--------------------------Creating Launch Template -----------------------------------------
resource "aws_launch_template" "Template" {
  name                                 = "TerraformLT"
  ebs_optimized                        = true
  image_id                             = "ami-0e6f2174f7905500d"
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                         = "c7gn.xlarge"
  key_name                              = "TerraformKey"
  vpc_security_group_ids                = [aws_security_group.EC2.id]
  iam_instance_profile {
  name = aws_iam_instance_profile.SSMProfile.name
}
  depends_on = [ aws_iam_instance_profile.SSMProfile ]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "TerraformInstance"
    }
  }

  user_data = base64encode(
    templatefile("FinalbootstrapAMI2023.tpl", {
      file       = aws_efs_file_system.efsclixx.id
      dbname     = "wordpressdb"
      mount_point = "/var/www/html"
      region     = "us-east-1"
      dbusername = data.aws_ssm_parameter.dbusername.value
      dbendpoint = data.aws_ssm_parameter.dbendpoint.value
      dbpassword = data.aws_ssm_parameter.dbpassword.value
      lb_dns     = aws_lb.ClixxLB.dns_name


    })
  )
}


#----------------------------------Bastion Sevrer ------------------------------------------------
resource "aws_instance" "example" {
  ami           = "ami-0028d7b894e925917"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.Publicsubnet1.id
  key_name      = "TerraformKey" 
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.Bastionssh.id] 
  tags = {
    Name = "bastion"
  }
}

#-------------------------------Autso scaling group -----------------------------------------------
resource "aws_autoscaling_group" "AG" {
  name                      = "TerraformAG"
  max_size                  = 5
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = true
  target_group_arns = [aws_lb_target_group.TG.arn]
  launch_template {
    id      = aws_launch_template.Template.id
    version = "$Latest"
  }  
  vpc_zone_identifier       = [aws_subnet.Privateubnet1.id,aws_subnet.Privateubnet2.id]
  timeouts {
    delete = "15m"
  }
  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "AzeezTerraformInstance"
    propagate_at_launch = false
  }
}


resource "aws_autoscaling_policy" "example" {
  autoscaling_group_name = aws_autoscaling_group.AG.name
  name                   = "Target Tracking Policy"
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50

  }
}


#-----------------------Creating sns topic for Autoscaling group --------------------------------------
resource "aws_sns_topic" "example" {
  name = "AutoscalingGroupInAction"
}

#----------------------Notification action ----------------------------------------------------
resource "aws_autoscaling_notification" "notifications" {
  group_names = [
    aws_autoscaling_group.AG.name  ]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.example.arn
}


#----------------------------------Creating sns subcription for those to receive notification ------------------------------------

resource "aws_sns_topic_subscription" "subscription" {
  topic_arn = aws_sns_topic.example.arn
  protocol  = "email"
  endpoint  = "azeezsolola@gmail.com"   
}

resource "aws_sns_topic_subscription" "subscription2" {
  topic_arn = aws_sns_topic.example.arn
  protocol  = "email"
  endpoint  = "michael.ojejinmi@stackitsolutions.com"   
}



#----------------------------------Creating role for ec2 instance so that the instance can assume this role and add instances to Fleet ---------------
resource "aws_iam_role" "SSMRole" {
  name = "SSMRole2"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "SSMAttach" {
  role       = aws_iam_role.SSMRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "SSMProfile" {
  name = "SSMProfile"
  role = aws_iam_role.SSMRole.name
}
