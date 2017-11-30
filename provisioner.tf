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
  }

  #############################################################
  # Upload and configure directories/files for Ansible
  #############################################################

  provisioner "file" {
    source	= "playbooks"
    destination	= "/etc/ansible/playbooks/"
  }

  # Generate Ansible hosts/inventory file from template
  provisioner "file" {
    content     = "${data.template_file.ansible_hosts.rendered}"
    destination = "/etc/ansible/playbooks/inventories/${var.ansible_inventory_name}/hosts"
  }

  #############################################################
  # Install Ansible, provision and test servers
  #############################################################

  provisioner "remote-exec" {
    inline = [
<<EOT
#!/bin/bash

# Cleanup code to run on exit (success or failure)
function finish {
  # Remove the uploaded deployment directories
  sudo rm -rf "/etc/ansible/playbooks"
}
trap finish EXIT

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
test -e '/etc/ansible/playbooks/site.retry' && echo "$(date) => [INFO]  => Removing site.retry file from previously failed run."
test -e '/etc/ansible/playbooks/site.retry' && sudo rm -f '/etc/ansible/playbooks/site.retry'

# Perform Ansible run to configure VMs
echo ""
echo "$(date) => [INFO]  => Perform Ansible run to configure VMs."
cd /etc/ansible/playbooks && \
ansible-playbook swarmplaybook.yml \
--inventory-file=inventories/${var.ansible_inventory_name}/hosts
    ]
  }
}
