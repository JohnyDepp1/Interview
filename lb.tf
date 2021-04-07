resource "aws_lb_target_group" "tg" {
  health_check {
    interval =  10
    path = "/"
    protocol = "HTTP"
    timeout = 5
    healthy_threshold = 5
    unhealthy_threshold = 2
  }
  name = "test-tg"
  port = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id =aws_vpc.vpc.id

}
resource "aws_lb" "my_lb"{
    name = "lb"
    internal = false
    security_groups = [aws_security_group.allow_web.id]
    subnets = [ aws_subnet.network1.id,aws_subnet.network3.id ]
    ip_address_type = "ipv4"
    load_balancer_type = "application"
}

resource "aws_lb_listener" "listener" {
    load_balancer_arn = aws_lb.my_lb.arn
    port = 80
    protocol = "HTTP"
    default_action {
      target_group_arn = aws_lb_target_group.tg.arn
      type = "forward"
    }
}

resource "aws_lb_target_group_attachment" "ec2_ws2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id = aws_instance.web-server2.id
  port = 80
}

resource "aws_lb_target_group_attachment" "ec2_ws" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web-server.id
  port             = 80
}