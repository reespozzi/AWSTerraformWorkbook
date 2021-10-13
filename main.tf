provider "aws" {
    region="eu-west-2"
}

resource "aws_instance" "FirstServer"{
    ami           ="ami-095379b4e8d257b76"
    instance_type ="t2.micro"

    tags          ={
        Name      ="Built in Terraform"
    }
}