# Automated Server Setup Script

This script will update a new server with zsh shell, neovim editor, exa listing, and nginx webserver.

It will also create few alias as below

```
alias v='sudo nvim'
alias vi='sudo nvim'
alias r='mv -t /tmp ' 
alias nf='neofetch'
alias l='exa -lar'
alias c='clear'
alias s='sudo'
alias ss='sudo systemctl'
alias update='sudo apt-get update && apt-get upgrade && apt-get dist-upgrade'
alias pyenv='source /home/nhr/pyenv/bin/activate'

```

## Packages that will be installed

1. zsh
2. neovim
3. exa
4. zsh-syntax-highlighting
5. zsh-autosuggestions
6. python3-venv
7. python3-pip
8. neofetch
9. git
10. nginx
11. certbot
12. python3-certbot-nginx

## Steps

This script will do the following steps:

1. Update server and upgrade it
2. Will install softwares
3. Create user from input and setup its neovim, zsh
4. Change hostname
5. Start nginx
