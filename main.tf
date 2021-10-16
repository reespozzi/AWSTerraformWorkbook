provider "aws" {
    region                      ="eu-west-2"
}

resource "aws_security_group" "sg"{
    name                        ="FirstServerSG"

    ingress{
        from_port               =var.server_port
        to_port                 =var.server_port
        protocol                ="tcp"
        #CIDR block specifies IP ranges, 0.0.0.0/0 covers all IP addresses
        cidr_blocks             =["0.0.0.0/0"]
    }
}

#LB don't allow traffic by default so also needs an SG
resource "aws_security_group" "alb_sg" { 
    name                        = "terraform-example-alb"
    
    ingress {
        from_port               =80
        to_port                 =80
        protocol                ="tcp" 
        cidr_blocks             = ["0.0.0.0/0"]
    }
    
    egress {
        from_port               =0
        to_port                 =0
        protocol                ="-1" 
        cidr_blocks             =["0.0.0.0/0"]
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
    target_group_arns           =[aws_lb_target_group.asg_target_group.arn]

    #more robust than the default EC2 type which just checks if it's down, this uses the target groups configuration to define what "healthy" is for an instance
    health_check_type           ="ELB"

    tag{
        key                     ="Name"
        value                   ="Autoscaling group member"
        propagate_at_launch     =true
    }
    lifecycle {
        create_before_destroy   =true
    }
    #deploys instances across different subnets from the VPC, each in a different datacentre for HA, this pulls list of subnets from AWS account
    vpc_zone_identifier         =data.aws_subnet_ids.subnets.ids
    #better of to keep instances running inside private subnets in PROD environment and route traffic to them in a secure manner
}   

#ALB most suited for simple HTTP/S traffic distribution between instances in the ASG
resource "aws_lb" "load_balancer"{
    name                        ="LoadBalancer"
    load_balancer_type          ="application"
    #configured to use all subnets in VPC
    subnets                     =data.aws_subnet_ids.subnets.ids   
    security_groups             =[aws_security_group.alb_sg.id]       
}

resource "aws_lb_listener" "http"{
    load_balancer_arn           =aws_lb.load_balancer.arn 
    port                        =80
    protocol                    ="HTTP"

    #default response for anything that doesn't match a listener rule
    default_action{
        type           ="fixed-response"

        fixed_response{
            content_type        ="text/plain"
            message_body        ="404! Sorry."
            status_code         =404
        }
    }
}

#can't use static list of instances here due to nature of ASGs so need to utilise connection between lb and asg in the ASG
resource "aws_lb_target_group" "asg_target_group"{ 
    name                        ="targetGroup" 
    port                        =var.server_port
    protocol                    ="HTTP"
    vpc_id                      =data.aws_vpc.default.id
    health_check {
        path                    ="/"
        protocol                ="HTTP"
        matcher                 ="200"
        interval                =15
        timeout                 =3
        healthy_threshold       =2
        unhealthy_threshold     =2
    }   
}

resource "aws_lb_listener_rule" "listener_rule"{    
    listener_arn               =aws_lb_listener.http.arn
    priority                    =100

    condition {
        path_pattern {
          values                =["*"]
        }
    }

    action{
        type                    ="forward"
        target_group_arn        =aws_lb_target_group.asg_target_group.arn
    }
    #forwards any path request to the target group containing the asg
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