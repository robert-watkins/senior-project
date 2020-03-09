# Senior Project Scripts  
### odoo-server.sh run:  
sudo su  
cd /  
dnf install -y git  
git clone https://github.com/robert-watkins/senior-project  
cd senior-project  
chmod +x odoo-server.sh  
./odoo-server.sh  
  
### Vagrant
The vagrant file creates a CentOS 8 vm with guest additions and runs the provision script  
The provision script updates, installs git, clones this repo, and makes it executable  
  
    To use vagrant:  
    cd senior-project/vagrant  
    vagrant up  
    \[select network adapter\]  
    vagrant ssh  
  
This will prepare the environment for odoo-server.sh  