data "aws_vpc" "default" { 
    default = true
}

data "aws_subnet_ids" "subnets"{ 
    vpc_id = data.aws_vpc.default.id
}