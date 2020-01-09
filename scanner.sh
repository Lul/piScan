#!/bin/bash

echo -e "piScan v0.01\n"
echo -e "created by John Thiell\n\n"

sys_check()
{
  if [ -d "/usr/share/nmap" ] && [ -e "/usr/share/nmap/scripts/nmap-vulners" ]; then
    return
  elif [ ! -d "/usr/share/nmap" ]; then
    echo -e "nmap not installed. Would you like to install it? (Y/N)\n"
    read install
    if [ $install == "Y" ] || [ $install == "y" ]; then
      sudo apt install nmap
      sys_check
    else
      exit
    fi
  elif [ ! -e "/usr/share/nmap/scripts/nmap-vulners" ]; then
    echo -e "'nmap-vulners' not installed. Would you like to install it? (Y/N)\n"
    read install
    if [ $install == "Y" ] || [ $install == "y" ]; then
      cd /usr/share/nmap/scripts; sudo git clone https://github.com/vulnersCom/nmap-vulners.git
      sys_check
    else
      exit
    fi
  else
    echo -e "Fatal Error, exiting."
    exit
  fi
}

selfip()
{
  ip="ip addr | grep 'state UP' -A2 | grep 'inet' | awk '{print \$2}'"
  eval $ip
}

discoversubnet() 
{
  iplist="ip addr | grep 'state UP' -A2 | grep 'inet' | awk '{print \$2}' | tail -n1 | cut -f1 -d '/' | cut -d '.' -f1,2,3"
  eval $iplist 
}

ping_all()
{
  ping -b -c 1 $1 > /dev/null
  [ $? -eq 0 ] && echo $i
}

enumerate()
{
  for i in $(discoversubnet).{1..255}
  do
    ping_all $i & disown
  done
}

ipscan()
{
  for i in $(enumerate)
  do
    nmap -p 1-65535 $i 
  done
}

vulnscan()
{
  for i in $(enumerate)
  do
    nmap -sV --script nmap-vulners -p1-65535 $i
  done
}

menu()
{
  echo "What would you like to do? 
        1: Display current machine's IPs
        2: Manual nmap command
        3: Enumerate all IP's on network
        4: Discover ports & services on all IP's
        5: Vulnerability Scan all IP's
        6: Exit"
  read minput
  if [ $minput -lt 1 ] || [ $minput -gt 6 ]; then
    echo -e "Invalid input.\n"
    menu
  else
  case $minput in
    "1") echo -e "\n$(selfip)\n"; menu;;
    "2") read mannmap; eval $mannmap; echo -e "\n"; menu;;
    "3") echo -e "\n$(enumerate)\n"; menu;;
    "4") echo -e "\n$(ipscan)\n"; menu;;
    "5") echo -e "\n$(vulnscan)\n"; menu;;
    "6") exit
  esac
  fi
}

sys_check
menu
