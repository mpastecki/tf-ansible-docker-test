resource "null_resource" "snode_destroy_proivisioner" {
  triggers {
    cluster_instance_ids = "${join(",", aws_instance.swarm-worker.*.id)}"
  }

  provisioner "remote-exec" {
    
  }
}
