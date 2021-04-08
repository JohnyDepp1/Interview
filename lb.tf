#creation of Load balancer target group in order to house
#multiple EC2 instances this together with the different 
#listener rules make a filtor for incoming requests, which
#are then routed to the instances that meet the set conditiion 
resource "aws_lb_target_group" "tg" {
  health_check {
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
  name        = "test-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.vpc.id

}
resource "aws_lb" "my_lb" {
  name               = "lb"
  internal           = false
  #security groups the LB is part of []
  security_groups    = [aws_security_group.allow_web.id]
  #subnets to route trafic to
  subnets            = [aws_subnet.network1.id, aws_subnet.network3.id]
  ip_address_type    = "ipv4"
  #Application load balancer is for routing of HTTP/HTTPS requests
  load_balancer_type = "application"
}

#Setting a condition to work with security groups
#in order for the LB to decide which requests go where
resource "aws_lb_listener" "listener" {
  #amazon name of the load balancer
  load_balancer_arn = aws_lb.my_lb.arn
  #port for the targets to receive traffic
  port              = 80
  protocol          = "HTTP"
  #what to do when the condition is met
  default_action {
    #amazon name of target group containing the instances
    target_group_arn = aws_lb_target_group.tg.arn
    #action type
    type             = "forward"
  }
}

#attachment of EC2 instances(web servers) to the LB target group
resource "aws_lb_target_group_attachment" "ec2_ws2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web-server2.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "ec2_ws" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web-server.id
  port             = 80
}