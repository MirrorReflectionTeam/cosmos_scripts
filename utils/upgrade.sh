#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/MirrorReflectionTeam/cosmos_scripts/main/utils/additional_commands.sh)

#-n paloma -i messenger -b 1785853 -v v1.1.0 -bi palomad 

while getopts n:i:b:v:bi: flag; do
  case "${flag}" in
  n) CHAIN_NAME=$OPTARG ;;
  i) CHAIN_ID=$OPTARG ;;
  b) TARGET_BLOCK=$OPTARG ;;
  v) VERSION=$OPTARG ;;
  bi) BINARY=$OPTARG ;;
  *) echo "OPS... I don't know what do you mean ${OPTARG}"
  esac
done

printLogo

echo -e "Now block is ${GREEN}$TARGET_BLOCK${NC} on your node: ${GREEN}$CHAIN_NAME${NC}, waiting for update to Version ${GREEN}$VERSION${NC}" && sleep 1
echo ""

for (( ; ; )); do
  height=$($BINARY status 2>&1 | jq -r .SyncInfo.latest_block_height)
  if ((height >= TARGET_BLOCK)); then
    bash <(curl -s https://raw.githubusercontent.com/MirrorReflectionTeam/cosmos_scripts/main/${CHAIN_NAME}/upgrade.sh)
    printGREEN "Successfull upgraded to version: $VERSION" && sleep 1
    $BINARY version --long | head
    break
  else
    echo -e "Current Node Block Height: ${GREEN}$height${NC}"
  fi
  sleep 5
done