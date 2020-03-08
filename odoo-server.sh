#!/bin/bash
# Install Odoo server and enable pos module on CentOS 8
# Robert Watkins
clean(){
clear
echo "   ____      __          ";
echo "  / __ \____/ /___  ____ ";
echo " / / / / __  / __ \/ __ \ ";
echo "/ /_/ / /_/ / /_/ / /_/ /";
echo "\____/\__,_/\____/\____/ ";
echo " "
}
clean
echo Updating...
dnf update -yq
dnf install -yq epel-release
clean
echo Installing dependencies...
dnf install -yq python36 python36-devel

dnf install -yq git gcc wget nodejs libxslt-devel bzip2-devel openldap-devel libjpeg-devel freetype-devel

clean
echo Adding odoo user
useradd -m -U -r -d /opt/odoo -s /bin/bash odoo

clean
echo Configuring Postgresql...
dnf install -yq postgresql postgresql-server postgresql-contrib

/usr/bin/postgresql-setup initdb

systemctl start postgresql
systemctl enable postgresql

su - postgres -c "createuser -s odoo"

clean
echo Doing other things...
cd /opt/ && wget https://downloads.wkhtmltopdf.org/0.12/0.12.5/wkhtmltox-0.12.5-1.centos7.x86_64.rpm
dnf localinstall -yq wkhtmltox-0.12.5-1.centos7.x86_64.rpm

clean
echo Installing Odoo...
su - odoo -c "git clone https://www.github.com/odoo/odoo --depth 1 --branch 13.0 /opt/odoo/odoo13"
su - odoo -c "cd /opt/odoo && python3 -m venv odoo13-venv"
su - odoo -c "source odoo13-venv/bin/activate"
pip3 install -r --user odoo odoo13/requirements.txt# > /dev/null 2>&1

clean
echo Configuring Odoo...
mkdir /opt/odoo/odoo13-custom-addons
chown odoo: /opt/odoo/odoo13-custom-addons

mkdir /var/log/odoo13 && touch /var/log/odoo13/odoo.log
chown -R odoo: /var/log/odoo13/

cat << EOF > /etc/odoo.conf
[options]
; This is the password that allows database operations:
admin_passwd = master_password
db_host = False
db_port = False
db_user = odoo
db_password = False
xmlrpc_port = 8069
; longpolling_port = 8072
logfile = /var/log/odoo13/odoo.log
logrotate = True
addons_path = /opt/odoo/odoo13/addons,/opt/odoo/odoo13-custom-addons
EOF
cat << EOF > /etc/systemd/system/odoo13.service
[Unit]
Description=Odoo13
#Requires=postgresql-10.6.service
#After=network.target postgresql-10.6.service
[Service]
Type=simple
SyslogIdentifier=odoo13
PermissionsStartOnly=true
User=odoo
Group=odoo
ExecStart=/opt/odoo/odoo13-venv/bin/python3 /opt/odoo/odoo13/odoo-bin -c /etc/odoo.conf
StandardOutput=journal+console
[Install]
WantedBy=multi-user.target
EOF

clean
echo Starting Odoo...
systemctl daemon-reload
systemctl start odoo13
systemctl enable odoo13

firewall-cmd --zone=public --permanent --add-port=8069
firewall-cmd --reload 

clean
echo "Installation is complete. Access the server at:"
echo -e "\e[1;31m https://$(/sbin/ip -o -4 addr list enp1s0 | awk '{print $4}' | cut -d/ -f1):8069 \e[0m"
