provider "aws" {
    region = "ap-south-1"
}

resource "aws_instance" "example"{
    ami = var.image
    instance_type = "t2.micro"

    user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World - From Rohan" > index.html
    nohup busybox httpd -f -p ${var.to_port} &
    EOF

    vpc_security_group_ids = [aws_security_group.instance-sg.id]

    tags = {
        Name = "Terraform-example"
    }
}

resource "aws_security_group" "instance-sg" {
    name = "terraform-example-SecGrp"
    ingress {
        from_port = var.from_port
        to_port = var.to_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_launch_configuration" "example"{
    image_id = var.image
    instance_type = var.instance_type
    security_groups = [aws_security_group.instance-sg.id]

    user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World - From Rohan" > index.html
    nohup busybox httpd -f -p ${var.to_port} &
    EOF
}

resource "aws_autoscaling_group" "IAC-AWS-ASG_Example"{
    launch_configuration = aws_launch_configuration.example.name
    vpc_zone_identifier = data.aws_subnet_ids.default.ids
    target_group_arns = [aws_lb_target_group.asg.arn]
    health_check_type = "ELB"
    min_size = 2
    max_size = 10

    tag {
        key = "Name"
        value = "terraform-asg-example"
        propagate_at_launch = true
    }

}

resource "aws_lb" "example" {
    name = "terraform-asg-example"
    load_balancer_type = "application"
    subnets = data.aws_subnet_ids.default.ids
    security_groups = [aws_security_group.alb-sg.id]
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.example.arn
    port = 80
    protocol = "HTTP"
    default_action{
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "404: page not found"
            status_code = 404
        }
    }
}

resource "aws_security_group" "alb-sg"{
    ingress{
            from_port = 80
            to_port = 80
            protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
    }
    egress{
            from_port = 0
            to_port = 0
            protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
    }

}

resource "aws_lb_target_group" "asg"{
    name = "terraform-asg-example"
    port = 80
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default.id
    
    health_check {
        path = "/"
        protocol = "HTTP"
        matcher = "200"
        interval = 15
        timeout = 3
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
}

resource "aws_lb_listener_rule" "asg"{
    listener_arn = aws_lb_listener.http.arn
    priority = 100

    condition {
        path_pattern {
            values = ["/static/*"]
        }
  }
    
    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.asg.arn
    }
}



//this is a data source block. it is needed to fetch some live data from teh aws account, such as default vpc, IAM use information etc..
data "aws_vpc" "default"{
    default = true
}
//this is a data source block. it is needed to fetch some live data from teh aws account, such as default vpc, IAM use information etc..
data "aws_subnet_ids" "default"{
    vpc_id = data.aws_vpc.default.id
}



variable "image" {
    default = "ami-0002bdad91f793433"
}
variable "from_port" {
    default = 8080
}
variable "to_port" {
    default = 8080
}
variable "instance_type" {
    default = "t2.micro"
}


