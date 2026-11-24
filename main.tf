
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