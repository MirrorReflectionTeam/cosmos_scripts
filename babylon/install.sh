#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/MirrorReflectionTeam/cosmos_scripts/main/utils/additional_commands.sh)

printLogo

CHAIN_ID="bbn-test1"
CHAIN_DENOM="ubbn"
BINARY_NAME="babylond"
BINARY_VERSION_TAG="v0.5.0"

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
rm -rf babylon
git clone https://github.com/babylonchain/babylon
cd babylon 
git checkout v0.5.0
make install
babylond version

printGREEN "5. Initialize the node" && sleep 1

babylond config chain-id bbn-test1
babylond init "$NODE_MONIKER" --chain-id bbn-test1

printGREEN "6. Download genesis and addrbook" && sleep 1

curl -L https://github.com/babylonchain/networks/blob/main/bbn-test1/genesis.tar.bz2?raw=true > genesis.tar.bz2
tar -xjf genesis.tar.bz2
rm -rf genesis.tar.bz2
mv genesis.json ~/.babylond/config/genesis.json
curl -s https://snapshots-cosmos.mirror-reflection.com/cosmos-testnet/babylon-testnet/addrbook.json > $HOME/.babylond/config/addrbook.json

printGREEN "7. Add seeds" && sleep 1

SEEDS="465cd1d6ada4a6e9643b64d9c2f7f0afcea02685@rpc.babylon-testnet.mirror-reflection.com:34656,03ce5e1b5be3c9a81517d415f65378943996c864@18.207.168.204:26656,a5fabac19c732bf7d814cf22e7ffc23113dc9606@34.238.169.221:26656"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.babylond/config/config.toml

printGREEN "8. Set pruning and minimum gaz price" && sleep 1

sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "17"|' \
  $HOME/.babylond/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ubbn"|g' $HOME/.babylond/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.babylond/config/config.toml
sed -i 's|^network *=.*|network = "mainnet"|g' $HOME/.babylond/config/app.toml
sed -i 's|^checkpoint-tag *=.*|checkpoint-tag = "bbn0"|g' $HOME/.babylond/config/app.toml

babylond tendermint unsafe-reset-all --home $HOME/.babylond --keep-addr-book

printLine

printGREEN "9. Changing port if you have more one node or enter 0 for default port" && sleep 1

source <(curl -s https://raw.githubusercontent.com/MirrorReflectionTeam/cosmos_scripts/main/utils/change_port.sh) babylond

printLine


printGREEN "10. Create a service" && sleep 1

sudo tee /etc/systemd/system/babylond.service > /dev/null << EOF
[Unit]
Description=Babylon Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which babylond) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF


printGREEN "11. Download snapshot and start service" && sleep 1

curl https://snapshots-cosmos.mirror-reflection.com/cosmos-testnet/babylon-testnet/bbn-test1_latest.tar | tar -xf - -C $HOME/.babylond/data
sudo systemctl daemon-reload
sudo systemctl enable babylond
sudo systemctl start babylond

printLine
echo -e "Check logs:            ${GREEN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${GREEN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "You can add wallet and validator with :   https://github.com/MirrorReflectionTeam/cosmos_testnet_manuals/tree/main/babylon#management"