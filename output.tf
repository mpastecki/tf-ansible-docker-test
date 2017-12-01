output "swarm master" {
  value = "${aws_instance.swarm-manager.0.public_ip}"
}

output "snodes count" {
  value = "${length(aws_instance.swarm-worker.*.id)}"
}
