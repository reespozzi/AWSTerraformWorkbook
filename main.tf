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

#configures each EC2 instance to be created inside the ASG cluster (note ami and vpc_security_group_id name changes)
resource "aws_launch_configuration" "launch_config"{
    image_id                    ="ami-095379b4e8d257b76"
    instance_type               ="t2.micro"
    #resource attribute references inside [], need to add sg ID into the Server instance
    security_groups             =[aws_security_group.sg.id]
    #<<-EOF and EOF allow multiline strings without newline characters
    user_data                   = <<-EOF
                                #!/bin/bash
                                echo "Hello there!" > index.html
                                nohup busybox httpd -f -p ${var.server_port} &
                                EOF
    #the ASG will try to revert any changes made to the launch config without this as the config is immutable
    lifecycle{
        create_before_destroy   =true 
    }
}

resource "aws_autoscaling_group" "autoscaler"{
    launch_configuration        =aws_launch_configuration.launch_config.name
    min_size                    =2
    max_size                    =10

    tag{
        key                     ="Name"
        value                   ="Autoscaling group member"
        propagate_at_launch     =true
    }
    lifecycle {
        create_before_destroy   =true
    }
    vpc_zone_identifier = data.aws_subnet_ids.subnets.ids

}

data "aws_vpc" "default" { 
    default = true
}

data "aws_subnet_ids" "subnets"{ 
    vpc_id = data.aws_vpc.default.id
}



/*    Create single EC2 t2.micro instance running simple web server
resource "aws_instance" "FirstServer"{
    ami                     ="ami-095379b4e8d257b76"
    instance_type           ="t2.micro"
    #resource attribute references inside [], need to add sg ID into the Server instance
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
}*/