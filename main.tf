resource "aws_vpc" "primary_vpc" {
    cidr_block = "10.0.0.0/16"
    provider = aws.primary_region_provider
}

resource "aws_subnet" "primary_vpc_subnet" {
    vpc_id = aws_vpc.primary_vpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true

    tags = {
        Name = "primary-vpc-subnet"
    }
}

resource "aws_instance" "primary_ec2_instance" {
    ami = data.aws_ami.ubuntu_24_04.id
    instance_type = var.ec2_instance_type
    subnet_id = aws_subnet.primary_vpc_subnet.id
    
    user_data = <<-EOF
            #!/bin/bash
            apt update && apt upgrade
            apt install -y apache2

            cat >> /var/www/html/index.html <<HTML
            <h1> Hello from ${var.aws_primary_region} </h1>
            <p> I run on: ${var.ec2_instance_type} </p>
            HTML

            systemctl restart apache2
            EOF

    tags = {
        Name = "primary-ec2-instance"
    }
}

resource "aws_security_group" "primary_vpc_security_group" {
    vpc_id = aws_vpc.primary_vpc.id
    description = "Primary VPC Security Group"
}

resource "aws_vpc_security_group_ingress_rule" "allow_ingress_ssh_primary_vpc" {
    security_group_id = aws_security_group.primary_vpc_security_group.id
    cidr_ipv4 = aws_vpc.primary_vpc.cidr_block
    from_port = 22
    to_port = 22
    ip_protocol = "ssh"
}


resource "aws_vpc" "secondary_vpc" {
    cidr_block = "10.1.0.0/16" 
    provider = aws.secondary_region_provider
}

resource "aws_subnet" "secondary_vpc_subnet" {
    vpc_id = aws_vpc.secondary_vpc.id 
    cidr_block = "10.1.1.0/24"
    map_public_ip_on_launch = true

    tags = {
        Name = "secondary-vpc-subnet"
    }
}

resource "aws_instance" "secondary_instance" {
    ami = data.aws_ami.ubuntu_24_04.id
    instance_type = var.ec2_instance_type
    subnet_id = aws_subnet.secondary_vpc_subnet.id

    user_data = <<-EOF
            #!/bin/bash
            apt update && apt upgrade
            apt install -y apache2

            cat >> /var/www/html/index.html <<HTML
            <h1> Hello from ${var.aws_secondary_region} </h1>
            <p> I run on: ${var.ec2_instance_type} </p>
            HTML

            systemctl restart apache2
            EOF

    tags = {
        Name = "secondary-ec2-instance"
    }
}

resource "aws_security_group" "secondary_vpc_security_group" {
    vpc_id = aws_vpc.secondary_vpc.id
    description = "Secondary VPC Security Group"
}

resource "aws_vpc_security_group_ingress_rule" "allow_ingress_ssh_secondary_vpc" {
    security_group_id = aws_security_group.secondary_vpc_security_group.id
    cidr_ipv4 = aws_vpc.secondary_vpc.cidr_block
    from_port = 22
    to_port = 22
    ip_protocol = "ssh"
}