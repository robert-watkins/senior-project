#!/bin/bash 
# Install Odoo server and enable pos module on CentOS 8

# Check if user is root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

dnf update
dnf install epel-release
dnf install python36 python36-devel

dnf install git gcc wget nodejs libxslt-devel bzip2-devel openldap-devel libjpeg-devel freetype-devel

useradd -m -U -r -d /opt/odoo -s /bin/bash odoo

dnf install postgresql postgresql-server postgresql-contrib

/usr/bin/postgresql-setup initdb

systemctl start postgresql
systemctl enable postgresql

su - postgres -c "createuser -s odoo"

cd /opt/ && wget https://downloads.wkhtmltopdf.org/0.12/0.12.5/wkhtmltox-0.12.5-1.centos7.x86_64.rpm
dnf localinstall wkhtmltox-0.12.5-1.centos7.x86_64.rpm

su - odoo

git clone https://www.github.com/odoo/odoo --depth 1 --branch 13.0 /opt/odoo/odoo13
cd /opt/odoo && python3 -m venv odoo13-venv
source odoo13-venv/bin/activate
pip3 install -r odoo13/requirements.txt
deactivate && exit

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

systemctl daemon-reload
systemctl start odoo13
systemctl enable odoo13

echo "Installation is complete. Access the server at:"
echo -e "\e[1;31m https://$(ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'):8069 \e[0m"