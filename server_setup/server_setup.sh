#!/bin/bash

#
#       ███╗   ██╗██╗██╗  ██╗ █████╗ ██████╗ ███████╗
#       ████╗  ██║██║██║  ██║██╔══██╗██╔══██╗██╔════╝
#       ██╔██╗ ██║██║███████║███████║██████╔╝███████╗
#       ██║╚██╗██║██║██╔══██║██╔══██║██╔══██╗╚════██║
#       ██║ ╚████║██║██║  ██║██║  ██║██║  ██║███████║
#       ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
#       DRAFTED BY [https://nih.ar] ON 11-05-2021.
#       SOURCE [server_setup.sh] LAST MODIFIED ON 12-06-2022.
#

echo "Automated Server Setup Script"

echo "Enter new hostname for the server:"
read host_name

echo "Enter new username for usercreation"
read user_name

echo "Server update started"
sleep 2

echo "apt-get update -y"
apt-get update -y
echo "update date"
echo "apt-get upgrade -y"
sleep 5

apt-get dist-upgrade -y
echo "upgrade done"
echo "sudo apt-get dist-upgrade -y"
sleep 5

apt-get dist-upgrade -y
echo "dist upgrade done"
echo "installing software"
sleep 5

apt-get install sudo zsh neovim exa bat zsh-syntax-highlighting zsh-autosuggestions python3-venv python3-pip neofetch git nginx certbot python3-certbot-nginx -y
echo "software installed"
echo "creating directories and moving files"
sleep 5

mkdir -p ~/.config/{nvim,zsh,.local/share,.cache}
mv init.vim ~/.config/nvim/
mv .zshrc ~/.config/zsh/
mv .alias ~/.config/
echo "Directories created and file moved"
echo "Changing shell to zsh"
sleep 5

chsh -s /bin/zsh
source .zprofile
echo "Shell changed"
echo "adding user $user_name"
sleep 5

useradd -m -s /bin/zsh $user_name && sudo passwd
usermod -aG sudo $user_name
cp -r .ssh/ .zprofile .config /home/$user_name/
cd /home/$user_name
chown -R $user_name:$user_name .config .zprofile .zshrc .ssh
echo "nhr user created"
echo "setup finished"
echo "changing hostname"
hostnamectl set-hostname $host_name
echo "Please update sshd"
sleep 5

nvim /etc/ssh/sshd_config
echo "Finished sshd configuration"
echo "restarting nginx sshd"
sleep 5

sudo systemctl restart sshd
sudo systemctl enable nginx
sudo systemctl start nginx
echo "restarted all service"
sleep 5

sudo zsh

