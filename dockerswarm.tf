resource "aws_instance" "swarm-manager" {
  ami           = "${lookup(var.AMIS, var.AWS_REGION)}"
  instance_type = "t2.micro"

  # the VPC subnet
  subnet_id = "${aws_subnet.main-public-1.id}"

  # the security group
  vpc_security_group_ids = ["${aws_security_group.allow-ssh.id}"]

  # the public SSH key
  key_name = "${aws_key_pair.mykeypair.key_name}"

  connection {
    user = "ubuntu"
    private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"
    agent = false
  }

  tags {
    Name = "swarmmanager"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D",
      "sudo sh -c 'echo \"deb https://apt.dockerproject.org/repo ubuntu-xenial main\" >> /etc/apt/sources.list.d/docker.list'",
      "sudo apt-get update",
      "sudo apt-get install linux-image-extra-$(uname -r) -y",
      "sudo apt-get install docker-engine -y",
      "sudo service docker start"
    ]
  }
}

resource "aws_instance" "swarm-worker" {
  ami           = "${lookup(var.AMIS, var.AWS_REGION)}"
  instance_type = "t2.micro"
  count = "${var.cluster_node_count}"

  # the VPC subnet
  subnet_id = "${aws_subnet.main-public-1.id}"

  # the security group
  vpc_security_group_ids = ["${aws_security_group.allow-ssh.id}"]

  # the public SSH key
  key_name = "${aws_key_pair.mykeypair.key_name}"

  connection {
    user = "ubuntu"
    private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"
    agent = false
  }

  tags {
    Name = "swarmnode-${count.index}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D",
      "sudo sh -c 'echo \"deb https://apt.dockerproject.org/repo ubuntu-xenial main\" >> /etc/apt/sources.list.d/docker.list'",
      "sudo apt-get update",
      "sudo apt-get install linux-image-extra-$(uname -r) -y",
      "sudo apt-get install docker-engine -y",
      "sudo service docker start"
    ]
  }

  depends_on = [
    "aws_instance.swarm-manager"
  ]
}

data "template_file" "ansible_hosts" {
  template = "${file("templates/ansiblehosts.tpl")}"
  vars = {
    swarmmanager	= "localhost"
    snodes_addresses	= "${join("\n", aws_instance.swarm-worker.*.private_dns)}"
  }
}
