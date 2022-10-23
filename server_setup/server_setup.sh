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

echo "sudo apt-get update -y"
sudo apt-get update -y
echo "update date"
echo "sudo apt-get upgrade -y"
sleep 5

sudo apt-get dist-upgrade -y
sudo "upgrade done"
echo "sudo apt-get dist-upgrade -y"
sleep 5

sudo apt-get dist-upgrade -y
echo "dist upgrade done"
echo "installing software"
sleep 5

sudo apt-get install zsh neovim exa zsh-syntax-highlighting zsh-autosuggestions python3-venv python3-pip neofetch git nginx certbot python3-certbot-nginx -y
echo "software installed"
echo "creating directories and moving files"
sleep 5

sudo mkdir -p ~/.config/{nvim,zsh,.local/share,.cache}
sudo mv init.vim ~/.config/nvim/
sudo mv .zshrc ~/.config/zsh/
sudo mv .zprofile ~/
echo "Directories created and file moved"
echo "Changing shell to zsh"
sleep 5

sudo chsh -s /bin/zsh
sudo source .zprofile
echo "Shell changed"
echo "adding user $user_name"
sleep 5

sudo useradd -m -s /bin/zsh $user_name && sudo passwd
sudo usermod -aG sudo $user_name
sudo cp -r .ssh/ .zprofile .config /home/$user_name/
cd /home/$user_name
sudo chown -R $user_name:$user_name .config .zprofile .zshrc .ssh
echo "nhr user created"
echo "setup finished"
echo "changing hostname"
sudo hostnamectl set-hostname $host_name
echo "Please update sshd"
sleep 5

sudo nvim /etc/ssh/sshd_config
echo "Finished sshd configuration"
echo "restarting nginx sshd"
sleep 5

sudo systemctl restart sshd
sudo systemctl enable nginx
sudo systemctl start nginx
echo "restarted all service"
sleep 5

sudo zsh

