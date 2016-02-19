# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "boxcutter/centos72"

  config.vm.synced_folder ".", "/iiif-image-server"
  config.vm.synced_folder "../iiif-image", "/iiif-image"

  config.vm.network "forwarded_port", guest: 80, host: 8088,
    auto_correct: true
  config.vm.network "forwarded_port", guest: 3000, host: 3000,
    auto_correct: true
  config.vm.network "private_network", ip: "192.168.33.15"

  config.vm.provider "virtualbox" do |vb|
    vb.linked_clone = true
  end

  config.vm.provision "ansible" do |ansible|
    ansible.playbook = 'ansible/development-playbook.yml'
    ansible.inventory_path = 'ansible/inventories/development.ini'
    ansible.limit = 'all'
  end

  config.ssh.forward_agent = true

end
