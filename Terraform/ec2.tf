data "aws_efs_file_system" "example" {
  file_system_id = aws_efs_file_system.dev_efs.id
}

##################### Key Pair #####################

resource "aws_key_pair" "pepperoni_tf_key" {
  key_name   = "pepperoni_tf_key"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

##################### Save Private Key Instance #####################

resource "local_file" "pepperoni_tf_key" {
  filename = "pepperoni_tf_key"
  content  = tls_private_key.rsa.private_key_pem
}

##################### Setup Server EC2 Instance #####################

resource "aws_instance" "setup_server" {
  ami           = data.aws_ami.amazon_linux_2.id  
  instance_type = "t2.micro"
  key_name      = aws_key_pair.pepperoni_tf_key.key_name
  subnet_id     = aws_subnet.pub_az_1.id
  vpc_security_group_ids = [aws_security_group.ssh_sg.id, aws_security_group.alb_sg.id, aws_security_group.webserver_sg.id]
}

##################### EC2 Server AZ1 Instance #####################

resource "aws_instance" "app_server_az1" {
  ami           = data.aws_ami.amazon_linux_2.id  
  instance_type = "t2.micro"
  key_name      = aws_key_pair.pepperoni_tf_key.key_name
  subnet_id     = aws_subnet.pri_app_az_1.id
  vpc_security_group_ids = [aws_security_group.webserver_sg.id]

  tags = {
    Name = "Server_AZ1"
  }

  user_data = <<-EOT
    #!/bin/bash
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user
    git clone https://github.com/AlexTNewell/possible-solution.git
    yum install -y amazon-efs-utils  # For Amazon Linux
    mkdir -p /var/www/docker_resources
    echo "data.aws_efs_file_system.dev_efs.dns_name:/ /var/www/docker_resources nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 0 0" | sudo tee -a /etc/fstab
    mount -a
    cp -r /home/ec2-user/possible-solution/* /var/www/docker_resources
    docker build anewellcloud/possible-solution:latest
    docker run -d -p 80:80 -v /var/www/docker_resources/main/sub:/www anewellcloud/possible-solution:latest
  EOT
}

##################### EC2 Server AZ2 Instance #####################


resource "aws_instance" "app_server_az2" {
  ami           = data.aws_ami.amazon_linux_2.id 
  instance_type = "t2.micro"
  key_name      = aws_key_pair.pepperoni_tf_key.key_name
  subnet_id     = aws_subnet.pri_app_az_2.id
  vpc_security_group_ids = [aws_security_group.webserver_sg.id]

  tags = {
    Name = "Server_AZ2"
  }

  user_data = <<-EOT
    #!/bin/bash
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user
    git clone https://github.com/AlexTNewell/possible-solution.git
    yum install -y amazon-efs-utils  # For Amazon Linux
    mkdir -p /var/www/docker_resources
    echo "data.aws_efs_file_system.dev_efs.dns_name:/ /var/www/docker_resources nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 0 0" | sudo tee -a /etc/fstab
    mount -a
    cp -r /home/ec2-user/possible-solution/* /var/www/docker_resources
    docker build anewellcloud/possible-solution:latest
    docker run -d -p 80:80 -v /var/www/docker_resources/main/sub:/www anewellcloud/possible-solution:latest
  EOT
}



##################### Bastion Host #####################

resource "aws_instance" "bastion_host" {
  ami           = data.aws_ami.amazon_linux_2.id  # Correctly reference the Amazon Linux 2 AMI data source
  instance_type = "t2.micro"
  key_name      = aws_key_pair.pepperoni_tf_key.key_name
  subnet_id     = aws_subnet.pub_az_1.id
  vpc_security_group_ids = [aws_security_group.ssh_sg.id]
  
  tags = {
    Name = "Bastion_Host"
  }

}


##################### Output Bastion Host #####################

output "bastion_host_instance_id" {
  value = aws_instance.bastion_host.id
}


