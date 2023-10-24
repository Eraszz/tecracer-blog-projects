packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
  }
}

locals {
 timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "this" {
  ami_name      = format("%s-%s",var.packer_image_name , local.timestamp)
  instance_type = var.instance_type
  region        = var.region
  source_ami_filter {
    filters = {
      name = var.source_ami_name
    }
    most_recent = true
    owners      = [var.source_ami_owner]
  }
  ssh_username = var.packer_image_ssh_username
}

build {
  sources = [
    "source.amazon-ebs.this"
  ]

  provisioner "ansible" {
    user = var.packer_image_ssh_username
    playbook_file = "./playbook.yml"
  }

  post-processor "manifest" {
        strip_path = true
    }
}
