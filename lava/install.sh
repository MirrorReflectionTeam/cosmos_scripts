#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/MirrorReflectionTeam/cosmos_scripts/main/utils/additional_commands.sh)

printLogo

CHAIN_ID="lava-testnet-1"
CHAIN_DENOM="ulava"
BINARY_NAME="lavad"
BINARY_VERSION_TAG="v0.6.0"

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

curl https://get.gitopia.com | bash
sudo mv /tmp/tmpinstalldir/git-remote-gitopia /usr/local/bin/

cd || return
rm -rf lava
git clone https://github.com/lavanet/lava
cd lava || return
git checkout v0.7.0
make install
lavad version

printGREEN "5. Initialize the node" && sleep 1

lavad config chain-id lava-testnet-1
lavad init "$NODE_MONIKER" --chain-id lava-testnet-1

printGREEN "6. Download genesis and addrbook" && sleep 1

curl -Ls https://rpc.lava-testnet.mirror-reflection.com/genesis | jq -r .result.genesis > $HOME/.lava/config/genesis.json
curl -Ls https://snapshots-cosmos.mirror-reflection.com/cosmos-testnet/lava-testnet/addrbook.json > $HOME/.lava/config/addrbook.json

printGREEN "7. Add seeds" && sleep 1

SEEDS="7e851a5714dff9276bd5a73b4d5c64bab6b1faca@rpc.lava-testnet.mirror-reflection.com:33656,3f472746f46493309650e5a033076689996c8881@lava-testnet.rpc.kjnodes.com:44659"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.lava/config/config.toml

printGREEN "8. Set pruning and minimum gaz price" && sleep 1

sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "10"|' \
  $HOME/.lava/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.025ulava"|g' $HOME/.lava/config/app.toml
lavad tendermint unsafe-reset-all --home $HOME/.lava --keep-addr-book

printLine

printGREEN "9. Changing port if you have more one node or enter 0 for default port" && sleep 1

source <(curl -s https://raw.githubusercontent.com/MirrorReflectionTeam/cosmos_scripts/main/utils/change_port.sh) lava

printLine


printGREEN "10. Create a service" && sleep 1

sudo tee /etc/systemd/system/lavad.service > /dev/null << EOF
[Unit]
Description=Lava Network Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which lavad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF


printGREEN "11. Download snapshot and start service" && sleep 1

curl https://snapshots-cosmos.mirror-reflection.com/cosmos-testnet/lava-testnet/lava-testnet-1_latest.tar | tar -xf - -C $HOME/.lava/data
sudo systemctl daemon-reload
sudo systemctl enable lavad
sudo systemctl start lavad

printLine
echo -e "Check logs:            ${GREEN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${GREEN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "You can add wallet and validator with :   https://github.com/MirrorReflectionTeam/cosmos_testnet_manuals/tree/main/gitopia#management"