resource "tls_private_key" "key_gen" {  
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_s3_bucket_object" "private_key" {  
  bucket  = var.ssh_bucket
  key     = var.instance_name
  content = tls_private_key.key_gen.private_key_openssh
}

resource "aws_key_pair" "key" {  
  key_name   = "${var.env_full_name}-key"
  public_key = tls_private_key.key_gen.public_key_openssh
}

resource "aws_instance" "ec2" {
  count = var.instance_count

  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.key.key_name
  subnet_id = var.subnet_id

  tags = {
    Name = var.instance_name
  }
} 