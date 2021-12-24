provider "aws" {
    region = "ap-south-1"
} 
resource "aws_instance" "example"{
    ami = "ami-0002bdad91f793433"
    instance_type = "t2.micro"

    user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World - From Rohan" > index.html
    nohup busybox httpd -f -p 8080 &
    EOF

    vpc_security_group_ids = [aws_security_group.instance-sg.id]

    tags = {
        Name = "Terraform-example"
    }
}
resource "aws_security_group" "instance-sg" {
    name = "terraform-example-SecGrp"
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    

}