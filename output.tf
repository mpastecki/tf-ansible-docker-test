output "swarm master" {
  value = "${aws_instance.swarm-manager.0.public_ip}"
}
