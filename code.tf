//Creating the key and security group which will allow the port 80.

provider "aws" {
  region = "ap-south-1"
  profile = "myansh"
}

variable "a" {
  type = string  
  default = my_key        
}

resource "aws_key_pair" "deployer" {
  key_name   = "mykey1111"
  public_key = var.a

}
resource "aws_security_group" "sgp1" {
  name        = "m_sgp1"
  description = "Allow http and ssh inbound traffic"
  vpc_id      = "vpc-cdffw2a9"
 
 ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    description = "ssh from VPC"
    from_port   = 22
    to_port     = 22
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

  tags = {
    Name = "m_sgp1 "
  }
  
 //Creating Instance
  
  resource "aws_instance" "web" {
  ami             = "ami-0447a12f28fddb066"
  instance_type   = "t2.micro"
  key_name        = "mykey1" 
  security_groups = ["launch-wizard-1"]
  tags = {
    Name = "inst1"
  }

//Creating and attaching EBS volume

resource "aws_ebs_volume" "ebsone" {
  availability_zone = ap-south-1b
  size              = 1
  tags = {
    Name = "myebsone"
  }
}

 resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.example.id}"
  instance_id = "${aws_instance.web.id}"
}

resource "null_resource" "nulllocal2"  {
        provisioner "local-exec" {
            command = "echo  ${aws_instance.web.public_ip} > publicip.txt"
        }
}



resource "null_resource" "nullremote3"  {

depends_on = [aws_ebs_volume.ebsone]

//Establishing connection

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/users/Akash/downloads/mykey1.pem")
    host     = aws_instance.web.public_ip
  }
  
//Code for Basic linux commands required

provisioner "remote-exec" {
    inline = [
	  "sudo yum install httpd -y",
      "sudo yum install git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/anshumanrajawat/Mypage.git /var/www/html/"
    ]
  }
}
resource "null_resource" "nulllocal1"  {


depends_on = [
    null_resource.nullremote3,
  ]

        provisioner "local-exec" {
            command = "start chrome  ${aws_instance.web.public_ip}"
        }
}


resource "null_resource" "null2"  {
  provisioner "local-exec" {
      command = "git clone https://github.com/anshumanrajawat/Mypage.git ./gitcode"
    }
}    

//Create S3 bucket and deploy image into the s3 bucket and change the permission to public.

resource "aws_s3_bucket" "bucket235" {
  bucket = "my-bucket235"
  acl    = "public-read"
  versioning {
  enabled = true
}

  tags = {
    Name        = "mybucket235"
    Environment = "Dev"
  }
}


resource "aws_s3_bucket_object" "obj1" {
  key = "img3.jpg"
bucket = aws_s3_bucket.bucket235.id
source = "./gitcode/img3.jpg"
acl="public-read"
}


//Creating a Cloudfront using s3 bucket which contains images 


resource "aws_cloudfront_distribution" "cloudfrontmytest" {
   depends_on = [aws_s3_bucket.bucket235
  ]
  
    origin {
        domain_name = "codeofweb.s3.amazonaws.com"
        origin_id = aws_s3_bucket.bucket235.id



        custom_origin_config {
            http_port = 80
            https_port = 80
            origin_protocol_policy = "match-viewer"
            origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
        }
    }


    enabled = true



    default_cache_behavior {
        allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods = ["GET", "HEAD"]
        target_origin_id = aws_s3_bucket.bucket235.id


        forwarded_values {
            query_string = false


            cookies {
               forward = "none"
            }
        }
        viewer_protocol_policy = "allow-all"
        min_ttl = 0
        default_ttl = 3600
        max_ttl = 86400
    }


    restrictions {
        geo_restriction {


            restriction_type = "none"
        }
    }


    viewer_certificate {
        cloudfront_default_certificate = true
    }
}


resource "null_resource" "null4"  {
  provisioner "local-exec" {
      command = "echo  ${aws_cloudfront_distribution.cloudfrontmytest.domain_name
} > cloudfrontURL.txt"
    }
}


