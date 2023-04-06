#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/MirrorReflectionTeam/cosmos_scripts/main/utils/additional_commands.sh)

printLogo

CHAIN_ID="ojo-devnet"
CHAIN_DENOM="uojo"
BINARY_NAME="ojod"
BINARY_VERSION_TAG="v0.1.2"

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

cd || return
rm -rf ojo
git clone https://github.com/ojo-network/ojo.git
cd ojo || return
git checkout v0.1.2
make install
ojod version

printGREEN "5. Initialize the node" && sleep 1

ojod config chain-id ojo-devnet
ojod init "$NODE_MONIKER" --chain-id ojo-devnet

printGREEN "6. Download genesis and addrbook" && sleep 1

curl -Ls https://rpc.ojo-testnet.mirror-reflection.com/genesis | jq -r .result.genesis > $HOME/.ojo/config/genesis.json
curl -Ls https://snapshots-cosmos.mirror-reflection.com/cosmos-testnet/ojo-testnet/addrbook.json > $HOME/.ojo/config/addrbook.json

printGREEN "7. Add seeds" && sleep 1

SEEDS="5264a9742c3e2fdb3803ff4af0ecb6e127c73ab1@rpc.ojo-testnet.mirror-reflection.com:27656,3f472746f46493309650e5a033076689996c8881@ojo-testnet.rpc.kjnodes.com:50659"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.ojo/config/config.toml

printGREEN "8. Set pruning and minimum gaz price" && sleep 1

sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "17"|' \
  $HOME/.ojo/config/app.toml

sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0uojo\"|" $HOME/.ojo/config/app.toml
ojod tendermint unsafe-reset-all --home $HOME/.ojo --keep-addr-book

printLine

printGREEN "9. Changing port if you have more one node or enter 0 for default port" && sleep 1

source <(curl -s https://raw.githubusercontent.com/MirrorReflectionTeam/cosmos_scripts/main/utils/change_port.sh) ojo

printLine


printGREEN "10. Create a service" && sleep 1

sudo tee /etc/systemd/system/ojod.service > /dev/null << EOF
[Unit]
Description=ojo-testnet node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which ojod) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF


printGREEN "11. Download snapshot and start service" && sleep 1

curl https://snapshots-cosmos.mirror-reflection.com/cosmos-testnet/ojo-testnet/ojo-devnet_latest.tar | tar -xf - -C $HOME/.ojo/data
sudo systemctl daemon-reload
sudo systemctl enable ojod
sudo systemctl start ojod

printLine
echo -e "Check logs:            ${GREEN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${GREEN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "You can add wallet and validator with :   https://github.com/MirrorReflectionTeam/cosmos_testnet_manuals/tree/main/ojo#management"