resource "null_resource" "snode_destroy_proivisioner" {
  triggers {
    cluster_instance = "${aws_instance.swarm-worker.*.id[count.index]}"
  }

  provisioner "remote-exec" {
    when = "destroy"
    connection {
      user = "ubuntu"
      private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"
      agent = false
      host = "${aws_instance.swarm-manager.public_ip}"
    }
    
    inline = [
      "echo ''",
      "echo '$(date) => [INFO]  => Scaling docker service to 0 on ${aws_instance.swarm-manager.public_ip}'",
      "sudo docker service scale ${var.docker_service}=0",
      "sleep 10s"
    ]
  }

  provisioner "remote-exec" {
    when = "destroy"
    connection {
      user = "ubuntu"
      private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"
      agent = false
      host = "${aws_instance.swarm-worker.*.public_ip[count.index]}"
    }
    inline = [
      "echo ''",
      "echo '$(date) => [INFO]  => Leaving the swarm from ${aws_instance.swarm-worker.*.public_ip[count.index]}'",
      "sudo docker swarm leave --force"
    ]
  }

  provisioner "remote-exec" {
    when = "destroy"
    connection {
      user = "ubuntu"
      private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"
      agent = false
      host = "${aws_instance.swarm-manager.public_ip}"
    }
    inline = [
      "echo ''",
      "echo '$(date) => [INFO]  => removing ${aws_instance.swarm-worker.*.private_dns[count.index]} from ${aws_instance.swarm-manager.public_ip}'",
      "sudo docker node rm --force ${element(split(".", aws_instance.swarm-worker.*.private_dns[count.index]), 0)}",
      "echo ${element(split(".", aws_instance.swarm-worker.*.private_dns[count.index]), 0)}"
    ]
  }    

  provisioner "remote-exec" {
    when = "destroy"
    connection {
      user = "ubuntu"
      private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"
      agent = false
      host = "${aws_instance.swarm-manager.public_ip}"
    }
    inline = [
<<EOT
echo ''
echo '$$(date) => [INFO]  => scaling up replicas number to have 2*worker-nodes-count: ${length(aws_instance.swarm-worker.*.id) * 2}'
sudo docker service scale ${var.docker_service}=${length(aws_instance.swarm-worker.*.id) * 2}
EOT
    ]
  }    

  count = "${length(aws_instance.swarm-worker.*.id)}"
}
