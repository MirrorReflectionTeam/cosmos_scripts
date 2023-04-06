#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/MirrorReflectionTeam/cosmos_scripts/main/utils/additional_commands.sh)

printLogo

CHAIN_ID="galileo-3"
CHAIN_DENOM="uandr"
BINARY_NAME="andromedad"
BINARY_VERSION_TAG="galileo-3-v1.1.0-beta1"

read -r -p "Enter node moniker: " NODE_MONIKER

printLine
echo -e "Node moniker:       ${GREEN}$NODE_MONIKER${NC}"
echo -e "Chain id:           ${GREEN}$CHAIN_ID${NC}"
echo -e "Chain demon:        ${GREEN}$CHAIN_DENOM${NC}"
echo -e "Binary version tag: ${GREEN}$BINARY_VERSION_TAG${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/MirrorReflectionTeam/cosmos_scripts/main/utils/install_dependies.sh)

printGREEN "4. Download and build binaries" && sleep 1

cd $HOME
rm -rf andromedad
git clone https://github.com/andromedaprotocol/andromedad.git
cd andromedad
git checkout galileo-3-v1.1.0-beta1
make install

printGREEN "5. Initialize the node" && sleep 1

andromedad config chain-id galileo-3
andromedad init "$NODE_MONIKER" --chain-id galileo-3

printGREEN "6. Download genesis and addrbook" && sleep 1

curl -s https://rpc.andromeda-testnet.mirror-reflection.com/genesis | jq -r .result.genesis > $HOME/.andromedad/config/genesis.json
curl -s https://snapshots-cosmos.mirror-reflection.com/cosmos-testnet/andromeda-testnet/addrbook.json > $HOME/.andromedad/config/addrbook.json

printGREEN "7. Add seeds" && sleep 1

SEEDS=""
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.andromedad/config/config.toml

printGREEN "8. Set pruning and minimum gaz price" && sleep 1

sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "17"|' \
  $HOME/.andromedad/config/app.toml

sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.0001uandr\"|" $HOME/.andromedad/config/app.toml
andromedad tendermint unsafe-reset-all --home $HOME/.andromedad --keep-addr-book

printLine

printGREEN "9. Changing port if you have more one node or enter 0 for default port" && sleep 1

source <(curl -s https://raw.githubusercontent.com/MirrorReflectionTeam/cosmos_scripts/main/utils/change_port.sh) andromedad

printLine


printGREEN "10. Create a service" && sleep 1

sudo tee /etc/systemd/system/andromedad.service > /dev/null << EOF
[Unit]
Description=andromeda-testnet node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which andromedad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF


printGREEN "11. Download snapshot and start service" && sleep 1

curl https://snapshots-cosmos.mirror-reflection.com/cosmos-testnet/andromeda-testnet/galileo-3_latest.tar | tar -xf - -C $HOME/.andromedad/data
sudo systemctl daemon-reload
sudo systemctl enable andromedad
sudo systemctl start andromedad

printLine
echo -e "Check logs:            ${GREEN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${GREEN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "You can add wallet and validator with :   https://github.com/MirrorReflectionTeam/cosmos_testnet_manuals/tree/main/andromeda#management"