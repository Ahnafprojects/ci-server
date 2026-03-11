# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Common settings for all VMs
  config.vm.box = "ubuntu/focal64"
  config.vbguest.auto_update = false
  config.vm.synced_folder ".", "/vagrant", disabled: false

  # Define the Master Node
  config.vm.define "k8s-master" do |master|
    master.vm.hostname = "k8s-master"
    master.vm.network "private_network", ip: "192.168.99.10"

    master.vm.provider "virtualbox" do |vb|
      vb.name = "k8s-master-rebuilt"
      vb.memory = 4096
      vb.cpus = 2
    end
  end

  # Define the Worker Node
  config.vm.define "k8s-worker-01" do |worker|
    worker.vm.hostname = "k8s-worker-01"
    worker.vm.network "private_network", ip: "192.168.99.11"

    worker.vm.provider "virtualbox" do |vb|
      vb.name = "k8s-worker-01-rebuilt"
      vb.memory = 2048
      vb.cpus = 2
    end
  end

  # Common provisioning for both nodes
  config.vm.provision "shell", inline: <<-SHELL
    echo "--- Provisioning Node: $(hostname) ---"
    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get update -y
    
    # Install Docker
    echo "--- Installing Docker ---"
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    sudo usermod -aG docker vagrant
    
    # Configure containerd and restart
    sudo mkdir -p /etc/containerd
    sudo containerd config default | sudo tee /etc/containerd/config.toml
    sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
    sudo systemctl restart containerd
    echo "--- Docker and containerd configured ---"
    
    # Install Kubernetes components
    echo "--- Installing K8s Tools ---"
    sudo apt-get install -y apt-transport-https
    sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl
    
    # Enable kubelet service
    sudo systemctl enable --now kubelet
    echo "--- K8s Tools Installed ---"

    # Set kernel parameters
    sudo modprobe br_netfilter
    echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee /etc/sysctl.d/k8s.conf
    echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.d/k8s.conf
    sudo sysctl --system

    echo "--- Node Ready ---"
  SHELL
end
