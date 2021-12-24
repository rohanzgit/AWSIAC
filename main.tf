provider "aws" {
    region = "ap-south-1"
} 
resource "aws_instance" "example"{
    ami = "ami-0002bdad91f793433"
    instance_type = "t2.micro"

    tags = {
        Name = "Terraform-example"
    }
}