#!/bin/bash -

#===============================================================================
#
#   FILE: sftp-jail.sh
#
#   USAGE: sftp-jail.sh -n|-a -u user -g group -d jail_path
#   EXAMPLE:
#             # create new jail with user storage
#             ./sftp-jail.sh -n -u storage -g www-data -d /var/jail
#
#             # add user storage2 to existing jail
#             ./sftp-jail.sh -a -u storage2 -g www-data -d /var/jail
#
#   AUTHOR: Jörg Stewig (nightmare@rising-gods.de)
#===============================================================================

#===============================================================================
#  FUNCTION DEFINITIONS
#===============================================================================

function usage
{
  echo -e "\nusage: $0 -n|-a -u user -g group -d jail_path"
  echo -e "-n, \t--new \t\tcreate new jail"
  echo -e "-a, \t--add \t\tadd user to existing jail"
  echo -e "-u, \t--user \t\tusername"
  echo -e "-d, \t--jail \t\tjail_dir"
  echo -e "-g, \t--group \tgroup"
}

function create_jaildir
{
  echo "[INFO] creating jail directory: ${1}"
  mkdir -p $1
}

function config_rssh # user jail
{
  sed -i  's/#allowscp/allowscp/g' /etc/rssh.conf
  sed -i  's/#allowsftp/allowsftp/g' /etc/rssh.conf

  echo "user=${1}:002:000110:${2}" >> /etc/rssh.conf
}

function mkchroot
{
  echo "[INFO] creating chroot environment: ${1}"
  bash /usr/share/doc/rssh/examples/mkchroot.sh $1
}

function user_add # user group dir
{
  echo "[INFO] creating user: ${1}"
  home_dir="${3}/home/${1}"
  mkdir -p "${3}/home"
  useradd -s /bin/bash -g $2 -m -d $home_dir $1
  passwd $1
  runuser -l $1 -c 'mkdir .ssh'
  runuser -l  $1 -c 'ssh-keygen -t rsa -N "" -f .ssh/id_rsa'
  runuser -l  $1 -c 'cat .ssh/id_rsa.pub > .ssh/authorized_keys'
  usermod -s /usr/bin/rssh $1
  grep "${3}" /etc/passwd > ${3}/etc/passwd
  echo "[INFO] key directory: ${home_dir}/.ssh/"
}

function fix_rssh
{
  chmod u+s /usr/lib/rssh/rssh_chroot_helper
}

function check-rssh
{
  command -v rssh >/dev/null 2>&1 || { echo >&2 "I require rssh but it's not installed. Use \"apt-get install rssh\"  to solve this problem. Aborting.."; exit 1; }
}

function check-group
{
  if ! grep -q "^${1}:" /etc/group; then echo >&2 "Group ${1} not exists. Please create it first or choose another group.."; exit 1; fi
}

function check-user
{
  if grep -q "^${1}:" /etc/passwd; then echo >&2 "User ${1} already exists. Please choose another user.."; exit 1; fi
}


#===============================================================================
#  MAIN SCRIPT
#===============================================================================

# check parameter count
if [ "$#" -lt 4 ]; then
  usage
  exit 1
fi

# check if rssh is installed
check-rssh

# parameter while-loop
while [ "$1" != "" ];
do
  case $1 in
    -a  | --add )
    ADD=1
    ;;
    -n  | --new )
    NEW=1
    ;;
    -u  | --user )  shift
    USER=$1
    ;;
    -d  | --jail )  shift
    JAIL=$1
    ;;
    -g  | --group ) shift
    GROUP=$1
    ;;
    -h  | --help )         usage
    exit
    ;;
    *)                     usage
    echo "The parameter $1 is not allowed"
    exit 1 # error
    ;;
  esac
  shift
done

# check user
check-user $USER

# check group if exists
check-group $GROUP

if [[ ( -n "$NEW" ) && ( -n "$ADD" ) ]]; then
  echo "[ERROR] You must choose between -a | --add and -n | --new"
  usage
  exit 1
fi

# check what to do
if [ -n "$NEW" ]; then # create new jail
  create_jaildir $JAIL
  config_rssh $USER $JAIL
  mkchroot $JAIL
  user_add $USER $GROUP $JAIL
  fix_rssh
elif [ -n "$ADD" ]; then
  config_rssh $USER $JAIL
  user_add $USER $GROUP $JAIL
else
  echo "Required param is missing.. --add or --new is important!"
  usage
  exit 1
fi

echo -e "[INFO] jailing done.. \n"
