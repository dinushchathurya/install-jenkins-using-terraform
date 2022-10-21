resource "aws_default_vpc" "default" {
    tags = {
        Name = "Jenkins VPC"
    }
}

data "aws_availability_zones" "available" {}

resource "aws_default_subnet" "default_az1" {
    availability_zone = data.aws_availability_zones.available.names[0]

    tags = {
        Name = "Default subnet for us-west-2a"
    }
}

resource "aws_security_group" "allow_tls" {
    name        = "allow_tls"
    description = "Allow TLS inbound traffic"
    vpc_id      = aws_default_vpc.default.id

    ingress {
        description      = "TLS from VPC"
        from_port        = 22
        to_port          = 22
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    ingress {
        description      = "TLS from VPC"
        from_port        = 8080
        to_port          = 8080
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name = "allow_tls"
    }
}

resource "aws_instance" "instance" {
    ami           = "ami-0c55b159cbfafe1f0"
    instance_type = "t2.micro"
    key_name      = "demovpc"
    subnet_id     = aws_default_subnet.default_az1.id
    vpc_security_group_ids = [aws_security_group.allow_tls.id]

    tags = {
        Name = "Jenkins"
    }
}

resource "null_resource" "jenkins" {
    depends_on = [aws_instance.instance]

    connection {
        type        = "ssh"
        user        = "ec2-user"
        private_key = file("C:\\Users\\admin\\Documents\\Desktop\\AWS Keys\\demovpc.pem")
        host        = aws_instance.instance.public_ip
    }

    provisioner "file" {
        source      = "install.sh"
        destination = "/tmp/install.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "chmod +x /tmp/install.sh",
            "sh /tmp/install.sh"
        ]
    }
}

