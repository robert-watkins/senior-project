#!/bin/bash
sudo dnf -y update
sudo dnf -y install git
cd /
sudo git clone https://github.com/robert-watkins/senior-project
sudo chmod +x /senior-project/odoo-server.sh
