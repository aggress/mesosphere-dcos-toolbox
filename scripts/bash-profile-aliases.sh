# DC/OS
alias dcad="dcos cluster setup --insecure --username=admin --password=password 192.168.33.11"
alias dcrm="for i in \$(dcos cluster list | tail -n +2 | awk {'print \$1'}); do echo \$i | sed 's/*//g' | xargs dcos cluster remove ; done"
alias dcla='sh ~/code/mesosphere-dcos-toolbox/scripts/launch-terraform-then-ansible-dcos.sh'

# Docker
alias doki='docker kill $(docker ps -q)'
alias doim='docker rmi -f $(docker images -aq)'
alias doda='docker images -qf dangling=true | xargs docker rmi -f'

