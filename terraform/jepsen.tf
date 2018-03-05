terraform {
  required_version = ">= 0.11.7"
}

provider "aws" {
  allowed_account_ids = [
    "750478353943",
  ]

  region = "${var.region}"
}

output "Control Node public IP" {
  value = "${aws_instance.control.public_ip}"
}

output "HA Storage S3 Bucket" {
  value = "${aws_s3_bucket.hastorage.bucket}"
}

output "Node private IPs" {
  value = "${sort(aws_instance.node.*.private_ip)}"
}

output "Node private DNS" {
  value = "${sort(aws_instance.node.*.private_dns)}"
}

output "Node public IPs" {
  value = "${sort(aws_instance.node.*.public_ip)}"
}

resource "aws_key_pair" "jepsen" {
  key_name   = "jepsen_${var.run_id}"
  public_key = "${file("id_rsa.pub")}"
}

resource "aws_security_group" "control" {
  name   = "jepsen_control_${var.run_id}"
  vpc_id = "${var.vpc_id}"

  ingress {
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

  tags {
    creator = "jepsen_${var.run_id}"
  }
}

resource "aws_security_group" "node" {
  name   = "jepsen_node_${var.run_id}"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = ["${aws_security_group.control.id}"]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  ingress {
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

  tags {
    creator = "jepsen_${var.run_id}"
  }
}

data "template_file" "userdata" {
  template = "${file("terraform/userdata.tpl")}"
}

resource "aws_instance" "control" {
  ami                    = "${var.ami}"
  iam_instance_profile   = "${aws_iam_instance_profile.default.name}"
  instance_type          = "${var.instance_type}"
  key_name               = "${aws_key_pair.jepsen.key_name}"
  user_data              = "${data.template_file.userdata.rendered}"
  vpc_security_group_ids = ["${aws_security_group.control.id}"]

  root_block_device {
    volume_size           = "${var.control_root_volume_size}"
    volume_type           = "gp2"
    delete_on_termination = true
  }

  provisioner "remote-exec" {
    connection {
      agent       = false
      private_key = "${file("id_rsa")}"
      user        = "admin"
    }

    inline = [
      "echo '${join("\n", sort(aws_instance.node.*.private_ip))}' > nodes",
      "cat nodes | xargs -n1 ssh-keyscan -t rsa >> ~/.ssh/known_hosts",
    ]
  }

  tags {
    name = "jepsen_controller"
    role = "jepsen_controller_${var.run_id}"
  }
}

resource "aws_instance" "node" {
  ami                    = "${var.ami}"
  count                  = "${var.nodes}"
  iam_instance_profile   = "${aws_iam_instance_profile.default.name}"
  instance_type          = "${var.instance_type}"
  key_name               = "${aws_key_pair.jepsen.key_name}"
  user_data              = "${data.template_file.userdata.rendered}"
  vpc_security_group_ids = ["${aws_security_group.node.id}"]

  root_block_device {
    volume_size           = "${var.node_root_volume_size}"
    volume_type           = "gp2"
    delete_on_termination = true
  }

  tags {
    name = "jepsen_node"
    role = "jepsen_node_${var.run_id}"
  }
}

resource "aws_s3_bucket" "hastorage" {
  bucket_prefix = "jepsen-flink-"
  force_destroy = true

  tags {
    name = "jepsen_${var.run_id}"
  }
}

resource "aws_iam_role" "default" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "hastorage-default" {
  name       = "jepsen-hastorage-default_${var.run_id}"
  roles      = ["${aws_iam_role.default.name}"]
  policy_arn = "${aws_iam_policy.hastorage.arn}"
}

resource "aws_iam_policy" "hastorage" {
  name = "jepsen-hastorage_${var.run_id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": ["s3:*"],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.hastorage.arn}",
        "${aws_s3_bucket.hastorage.arn}/*"]
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "default" {
  name = "jepsen_${var.run_id}"
  role = "${aws_iam_role.default.name}"
}
