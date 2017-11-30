resource "null_resource" "smanager_provisioner" {
  depends_on = [
    "aws_instance.swarm-manager",
    "aws_instance.swarm-worker"
  ]

  triggers {
    cluster_instance_ids = "${join(",", concat(aws_instance.swarm-manager.*.id, aws_instance.swarm-worker.*.id))}"
  }

  connection {
    host	= "${aws_instance.swarm-manager.public_ip}"
    user = "ubuntu"
    private_key = "${file(var.PATH_TO_PRIVATE_KEY)}"
    agent = false
  }

  #############################################################
  # Upload and configure directories/files for Ansible
  #############################################################

  provisioner "file" {
    source = "${var.PATH_TO_PRIVATE_KEY}"
    destination = "/home/ubuntu/.ssh/${var.PRIVATE_KEY_FILE_NAME}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /home/ubuntu/ansible/playbooks/inventories/${var.ansible_inventory_name}/",
      "sudo chown -R ubuntu:ubuntu /home/ubuntu/ansible",
      "sudo chown ubuntu:ubuntu /home/ubuntu/.ssh/${var.PRIVATE_KEY_FILE_NAME}",
      "sudo chmod 600 /home/ubuntu/.ssh/${var.PRIVATE_KEY_FILE_NAME}"
    ]
  }

  provisioner "file" {
    source	= "playbooks"
    destination	= "/home/ubuntu/ansible/"
  }

  # Generate Ansible hosts/inventory file from template
  provisioner "file" {
    content     = "${data.template_file.ansible_hosts.rendered}"
    destination = "/home/ubuntu/ansible/playbooks/inventories/${var.ansible_inventory_name}/hosts"
  }

  #############################################################
  # Install Ansible, provision and test servers
  #############################################################

  provisioner "remote-exec" {
    inline = [
<<EOT
#!/bin/bash

## Cleanup code to run on exit (success or failure)
#function finish {
#  # Remove the uploaded deployment directories
#  sudo rm -rf "/home/ubuntu/ansible/playbooks"
#}
#trap finish EXIT

# Install Ansible and dependencies
echo ""
echo "$(date) => [INFO]  => Install Ansible and dependencies."
sudo apt-get install software-properties-common -y
sudo apt-add-repository ppa:ansible/ansible -y
sudo apt-get update -y && sudo apt-get -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install python-jmespath ansible -y

# Set Ansible configuration via environment variables
echo ""
echo "$(date) => [INFO]  => Set Ansible configuration via environment variables."
export ANSIBLE_HOST_KEY_CHECKING=False

# Remove site.retry file from a previously failed Ansible run
echo ""
echo "$(date) => [INFO]  => Checking for site.retry file from a previously failed Ansible run."
test -e '/home/ubuntu/ansible/playbooks/site.retry' && echo "$(date) => [INFO]  => Removing site.retry file from previously failed run."
test -e '/home/ubuntu/ansible/playbooks/site.retry' && sudo rm -f '/home/ubuntu/ansible/playbooks/site.retry'

# Create ansible playbooks directory
echo ""
echo "$(date) => [INFO]  => Checking for playbooks directoy."
test -d '/home/ubuntu/ansible/playbooks' && echo "Folder exists" || mkdir -p '/home/ubuntu/ansible/playbooks'

# Perform Ansible run to configure VMs
echo ""
echo "$(date) => [INFO]  => Perform Ansible run to configure VMs."
cd /home/ubuntu/ansible/playbooks && \
ansible-playbook swarmplaybook.yml \
--inventory-file=inventories/${var.ansible_inventory_name}/hosts \
--key-file="/home/ubuntu/.ssh/${var.PRIVATE_KEY_FILE_NAME}"

# Initialize redis service
echo ""
echo "$(date) => [INFO]  => Perform Ansible run to start service."
cd /home/ubuntu/ansible/playbooks && \
ansible-playbook swarmserviceplaybook.yml \
--inventory-file=inventories/${var.ansible_inventory_name}/hosts \
--key-file="/home/ubuntu/.ssh/${var.PRIVATE_KEY_FILE_NAME}" \
--extra-vars 'docker_service=${var.docker_service}'
EOT
    ]
  }
}
