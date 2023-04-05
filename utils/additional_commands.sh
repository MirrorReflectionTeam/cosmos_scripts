NC="\e[0m"           # 
GREEN="\033[0;32m" 
RED="\e[1m\e[1;91m" 

function printLogo {
  bash <(curl -s https://raw.githubusercontent.com/chabanyknikita/cosmos_scripts/main/utils/mirror_reflection_logo.sh)
}

function printLine {
  echo "---------------------------------------------------------------------------------------"
}

function printGREEN {
  echo -e "${GREEN}${1}${NC}"
}

function printRed {
  echo -e "${RED}${1}${NC}"
}

function addToPath {
  source $HOME/.bash_profile
  PATH_EXIST=$(grep ${1} $HOME/.bash_profile)
  if [ -z "$PATH_EXIST" ]; then
    echo "export PATH=$PATH:${1}" >>$HOME/.bash_profile
  fi
}