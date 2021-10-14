provider "aws" {
    region="eu-west-2"
}

resource "aws_security_group" "sg"{
    name            ="FirstServerSG"

    ingress{
        from_port   =var.server_port
        to_port     =var.server_port
        protocol    ="tcp"
        #CIDR block specifies IP ranges, 0.0.0.0/0 covers all IP addresses
        cidr_blocks =["0.0.0.0/0"]
    }
}

resource "aws_instance" "FirstServer"{
    ami                     ="ami-095379b4e8d257b76"
    instance_type           ="t2.micro"
    #resource attribute references inside []
    vpc_security_group_ids  =[aws_security_group.sg.id]
    #<<-EOF and EOF allow multiline strings without newline characters
    user_data               = <<-EOF
                            #!/bin/bash
                            echo "Hello there!" > index.html
                            nohup busybox httpd -f -p ${var.server_port} &
                            EOF

    tags                    ={
        Name                ="Built in Terraform"
    }
}