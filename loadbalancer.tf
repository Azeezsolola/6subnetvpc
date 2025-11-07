#----------------------------------Load Balancer Creation Block ---------------------------------------------
resource "aws_lb" "ClixxLB" {
  name               = "TerraformLB"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.LB.id]
  subnets            = [aws_subnet.Publicsubnet1.id,aws_subnet.Publicsubnet2.id]
  enable_deletion_protection = false
  tags = {
    Environment = "Test"
  }
  depends_on = [ aws_subnet.Publicsubnet1,aws_subnet.Publicsubnet2 ]
}


#-------------------------------Load Balancer Target group which is intance -------------------------------------
resource "aws_lb_target_group" "TG" {
  name     = "LoadBalancerTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.TerraformVPC.id
  health_check {
    path                = "/index.php"   
    matcher             = "200-399"
    interval            = 30
    timeout             = 29
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }
}

#----------------------------------Load Balancer Listener ----------------------------------------------------------
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.ClixxLB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TG.arn
  }
}


