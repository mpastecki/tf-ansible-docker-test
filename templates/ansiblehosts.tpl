#------------------------
# Child groups
#------------------------
[docker_swarm_manager_servers]
${swarmmanager}

[docker_swarm_worker_servers]
${snodes_addresses}

#------------------------
# Parent groups
#------------------------
[docker_swarm_servers:children]
docker_swarm_manager_servers
docker_swarm_worker_servers
