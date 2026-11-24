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
    provider = aws.primary_region_provider
    ami = data.aws_ami.ubuntu_24_04.id
    instance_type = var.ec2_instance_type
    subnet_id = aws_subnet.primary_vpc_subnet.id
    vpc_security_group_ids = [aws_security_group.primary_vpc_security_group.id]
    
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
    provider = aws.primary_region_provider
    description = "Primary VPC Security Group"
}

resource "aws_vpc_security_group_ingress_rule" "allow_ingress_ssh_primary_vpc" {
    security_group_id = aws_security_group.primary_vpc_security_group.id
    cidr_ipv4 = aws_vpc.primary_vpc.cidr_block
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "primary_icmp" {
    security_group_id = aws_security_group.primary_vpc_security_group.id
    from_port = -1
    to_port = -1 
    cidr_ipv4 = aws_vpc.secondary_vpc.cidr_block
    ip_protocol = "icmp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_tcp_from_secondary" {
    security_group_id = aws_security_group.primary_vpc_security_group.id
    cidr_ipv4 = aws_vpc.secondary_vpc.cidr_block
    from_port = 0
    to_port = 65535
    ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "primary_all_out" {
    security_group_id = aws_security_group.primary_vpc_security_group.id
    ip_protocol = "-1"
    cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_route_table" "primary_vpc_route_table" {
    vpc_id = aws_vpc.primary_vpc.id
    provider = aws.primary_region_provider
}

resource "aws_route" "primary_to_secondary" {
    provider = aws.primary_region_provider
    route_table_id = aws_route_table.primary_vpc_route_table.id
    destination_cidr_block = aws_vpc.secondary_vpc.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.peering_connection.id

    depends_on = [ aws_vpc_peering_connection_accepter.accepter ]
}

resource "aws_route_table_association" "primary_association" {
    provider = aws.primary_region_provider
    subnet_id = aws_subnet.primary_vpc_subnet.id
    route_table_id = aws_route_table.primary_vpc_route_table.id
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
    provider = aws.secondary_region_provider
    ami = data.aws_ami.ubuntu_24_04.id
    instance_type = var.ec2_instance_type
    subnet_id = aws_subnet.secondary_vpc_subnet.id
    vpc_security_group_ids = [aws_security_group.secondary_vpc_security_group.id]

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
    provider = aws.secondary_region_provider
    description = "Secondary VPC Security Group"
}

resource "aws_vpc_security_group_ingress_rule" "allow_ingress_ssh_secondary_vpc" {
    security_group_id = aws_security_group.secondary_vpc_security_group.id
    cidr_ipv4 = aws_vpc.secondary_vpc.cidr_block
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_tcp_from_primary" {
    security_group_id = aws_security_group.secondary_vpc_security_group.id
    cidr_ipv4 = aws_vpc.primary_vpc.cidr_block
    from_port = 0
    to_port = 65535
    ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "secondary_icmp" {
    security_group_id = aws_security_group.secondary_vpc_security_group.id
    cidr_ipv4 = aws_vpc.primary_vpc.cidr_block
    from_port = -1
    to_port = -1
    ip_protocol = "icmp"
}

resource "aws_vpc_security_group_egress_rule" "secondary_all_out" {
    security_group_id = aws_security_group.secondary_vpc_security_group.id
    ip_protocol = "-1"
    cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_route_table" "secondary_vpc_route_table" {
    vpc_id = aws_vpc.secondary_vpc.id
    provider = aws.secondary_region_provider
}

resource "aws_route" "secondary_to_primary" {
    provider = aws.secondary_region_provider
    route_table_id = aws_route_table.secondary_vpc_route_table.id
    destination_cidr_block = aws_vpc.primary_vpc.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.peering_connection.id

    depends_on = [ aws_vpc_peering_connection_accepter.accepter ]
}


resource "aws_route_table_association" "secondary_association" {
    provider = aws.secondary_region_provider
    subnet_id = aws_subnet.secondary_vpc_subnet.id
    route_table_id = aws_route_table.secondary_vpc_route_table.id
}

resource "aws_vpc_peering_connection" "peering_connection" {
    provider = aws.primary_region_provider
    vpc_id = aws_vpc.primary_vpc.id 
    peer_vpc_id = aws_vpc.secondary_vpc.id
    peer_region = var.aws_secondary_region
}

resource "aws_vpc_peering_connection_accepter" "accepter" {
    provider = aws.secondary_region_provider
    vpc_peering_connection_id = aws_vpc_peering_connection.peering_connection.id
    auto_accept = true
  
}