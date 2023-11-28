data "aws_ami" "amazon-2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
  owners = ["amazon"]
}

resource "aws_iam_instance_profile" "cicd_profile" {
  name = "cicd_profile"
  role = aws_iam_role.ec2_cicd_role.name
}

resource "aws_iam_role_policy_attachment" "attach1" {
  role       = aws_iam_role.ec2_cicd_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

resource "aws_iam_role_policy_attachment" "attach2" {
  role       = aws_iam_role.ec2_cicd_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "ec2_cicd_role" {
  name = "ec2_cicd_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_instance" "cicd_instance" {
  ami                  = data.aws_ami.amazon-2.id
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.cicd_profile.name
  user_data            = <<EOF
#!/bin/bash
yum update
yum install -y ruby
yum install -y wget
cd /home/ec2-user
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
chmod +x ./install
./install auto

# not work !!! find another solution!!!
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 16
npm install -g pm2
npm install -g yarn
sudo ln -s "$(which node)" /sbin/node
sudo ln -s "$(which npm)" /sbin/npm
sudo ln -s "$(which pm2)" /sbin/pm2
sudo ln -s "$(which yarn)" /sbin/yarn
EOF
  tags = {
    Name = "cicd_instance"
  }
}