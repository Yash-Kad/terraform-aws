provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "flask_express_sg" {
  name        = "flask-express-sg"
  description = "Security group for Flask and Express app"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "flask_express" {
  ami                    = "ami-0ced6a024bb18ff2e" 
  instance_type          = "t3.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.flask_express_sg.id]
  user_data = file("user-data.sh")

  tags = {
    Name = "Flask-Express-EC2"
  }
}
