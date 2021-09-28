// Create VPC
resource "aws_vpc" "vpc_name" {
  count                = var.create_vpc ? 1 : 0
  cidr_block           = var.vpc_ipv4_cidr
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"
  tags = {
    Name = "${var.vpc_name}-VPC"
  }
}

// Create Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
  count  = var.create_vpc && var.create_igw && length(local.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.vpc_name[0].id
  tags = merge(
    {
      "Name" = format(
        "%s-InternetGateway",
        var.vpc_name
      )
    },
  )
}

// Create Subnet
resource "aws_subnet" "public" {
  count                   = var.create_vpc && length(local.public_subnets) > 0 && length(local.public_subnets) >= length(local.availability_zones) ? length(local.public_subnets) : 1
  vpc_id                  = aws_vpc.vpc_name[0].id
  cidr_block              = element(concat(local.public_subnets, [""]), count.index)
  availability_zone       = length(regexall("^[a-z]{2}-", element(local.availability_zones, count.index))) > 0 ? element(local.availability_zones, count.index) : null
  availability_zone_id    = length(regexall("^[a-z]{2}-", element(local.availability_zones, count.index))) == 0 ? element(local.availability_zones, count.index) : null
  map_public_ip_on_launch = var.map_public_ip_on_launch
  depends_on              = [aws_internet_gateway.internet_gateway]
  tags = merge(
    {
      "Name" = format(
        "%s-${var.public_subnet_name}-%s",
        var.vpc_name,
        element(local.availability_zones, count.index),
      )
    },
  )
}

// Modify Default_Route_Table
resource "aws_route" "public_internet_gateway" {
  count                  = var.create_vpc && var.create_igw && length(local.public_subnets) > 0 ? 1 : 0
  route_table_id         = aws_vpc.vpc_name[0].default_route_table_id
  destination_cidr_block = var.default_cidr
  gateway_id             = element(aws_internet_gateway.internet_gateway.*.id, count.index)
  timeouts {
    create = "5m"
  }
}

resource "aws_default_route_table" "default_route_table" {
  count                  = var.create_vpc ? 1 : 0
  default_route_table_id = aws_vpc.vpc_name[0].default_route_table_id
  tags = merge(
    {
      "Name" = format(
        "%s-DefaultRouteTable",
        var.vpc_name
      )
    },
  )
}

resource "aws_route_table_association" "public_subnets" {
  count          = var.create_vpc && length(local.public_subnets) > 0 ? length(local.public_subnets) : 0
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_vpc.vpc_name[0].default_route_table_id
}

// Create Network ACL From Array Of Rules
resource "aws_default_network_acl" "network_acl_subnet" {
  default_network_acl_id = aws_vpc.vpc_name[0].default_network_acl_id
  dynamic "ingress" {
    for_each = [for rule_obj in local.nacl_ingress_rules : {
      rule_no    = rule_obj.rule_num
      protocol   = rule_obj.protocol
      portfrom   = rule_obj.portfrom
      portto     = rule_obj.portto
      cidr_block = rule_obj.cidr_block
      action     = rule_obj.action
    }]
    content {
      rule_no    = ingress.value["rule_no"]
      protocol   = ingress.value["protocol"]
      from_port  = ingress.value["portfrom"]
      to_port    = ingress.value["portto"]
      cidr_block = ingress.value["cidr_block"]
      action     = ingress.value["action"]
    }
  }
  dynamic "egress" {
    for_each = [for rule_obj in local.nacl_egress_rules : {
      rule_no    = rule_obj.rule_num
      protocol   = rule_obj.protocol
      portfrom   = rule_obj.portfrom
      portto     = rule_obj.portto
      cidr_block = rule_obj.cidr_block
      action     = rule_obj.action
    }]
    content {
      rule_no    = egress.value["rule_no"]
      protocol   = egress.value["protocol"]
      from_port  = egress.value["portfrom"]
      to_port    = egress.value["portto"]
      cidr_block = egress.value["cidr_block"]
      action     = egress.value["action"]
    }
  }
  tags = {
    Name = "${var.vpc_name}-DefaultNetworkACL"
  }
}

// Create Secuirty Group From Array Of Rules
resource "aws_default_security_group" "security_group" {
  vpc_id = aws_vpc.vpc_name[0].id
  dynamic "ingress" {
    for_each = [for rule_obj in local.sg_ingress_rules : {
      protocol    = rule_obj.protocol
      portfrom    = rule_obj.portfrom
      portto      = rule_obj.portto
      cidr_blocks = rule_obj.cidr_blocks
      description = rule_obj.description
    }]
    content {
      protocol    = ingress.value["protocol"]
      from_port   = ingress.value["portfrom"]
      to_port     = ingress.value["portto"]
      cidr_blocks = ingress.value["cidr_blocks"]
      description = ingress.value["description"]
    }
  }
  dynamic "egress" {
    for_each = [for rule_obj in local.sg_egress_rules : {
      protocol    = rule_obj.protocol
      portfrom    = rule_obj.portfrom
      portto      = rule_obj.portto
      cidr_blocks = rule_obj.cidr_blocks
      description = rule_obj.description
    }]
    content {
      protocol    = egress.value["protocol"]
      from_port   = egress.value["portfrom"]
      to_port     = egress.value["portto"]
      cidr_blocks = egress.value["cidr_blocks"]
      description = egress.value["description"]
    }
  }
  tags = {
    Name = "${var.vpc_name}-SecurityGroup"
  }
}

// Create Key Pair If Not Exists
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "keypair" {
  key_name   = var.vpc_name
  public_key = tls_private_key.this.public_key_openssh
  tags = {
    Name = "${var.vpc_name}-Keypair"
  }
}
resource "local_file" "pem_file" {
  filename             = pathexpand("${path.module}/${aws_key_pair.keypair.key_name}.pem")
  file_permission      = "600"
  directory_permission = "700"
  sensitive_content    = tls_private_key.this.private_key_pem
}

// Create EC2 Instance With Latest AMI Avilable  With AWS. Best In Case , Not Aware Off AMI Id Need To BE Selected.
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["self", "amazon"]
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.????????.?-x86_64-gp2"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
resource "aws_instance" "ec2_instance" {
  ami                                  = data.aws_ami.amazon-linux-2.id
  count                                = var.instance_count
  vpc_security_group_ids               = ["${aws_default_security_group.security_group.id}"]
  instance_type                        = var.instance_type
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  tenancy                              = var.tenancy
  disable_api_termination              = var.disable_api_termination
  key_name                             = var.vpc_name
  subnet_id                            = element(aws_subnet.public.*.id, count.index)
  user_data                            = file("UserData.sh")
  tags = merge(
    {
      "Name" = var.instance_count > 1 || var.use_num_suffix ? format("%s-EC2${var.num_suffix_format}", var.vpc_name, count.index + 1) : var.vpc_name
    },
    var.tags,
  )
  volume_tags = var.enable_volume_tags ? merge(
    {
      "Name" = var.instance_count > 1 || var.use_num_suffix ? format("%s-EC2Volume${var.num_suffix_format}", var.vpc_name, count.index + 1) : var.vpc_name
    },
    var.volume_tags,
  ) : null

  /* File Provisioner To Upload File In Target /tmp Directory , Becuase It does'nt Have Elevated Permission.*/

  provisioner "file" {
    source      = "index.html"
    destination = "/tmp/index.html"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = self.public_dns
      timeout     = "30m"
      agent       = false
      private_key = file("${path.module}/${aws_key_pair.keypair.key_name}.pem")
    }
  }

/* Remote-Exec Provisioner To Copy A File In Target /var/www/html Directory.*/
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = self.public_dns
      timeout     = "30m"
      agent       = false
      private_key = file("${path.module}/${aws_key_pair.keypair.key_name}.pem")
    }
    inline = [
      "sudo cp -arpv /tmp/index.html /var/www/html/index.html",
      "sudo systemctl stop httpd.service",
      "sudo systemctl start httpd.service"
    ]
  }
}
