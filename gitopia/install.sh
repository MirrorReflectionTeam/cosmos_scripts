#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/chabanyknikita/cosmos_scripts/main/utils/additional_commands.sh)

printLogo

CHAIN_ID="gitopia-janus-testnet-2"
CHAIN_DENOM="utlore"
BINARY_NAME="gitopiad"
BINARY_VERSION_TAG="v1.2.0"

read -r -p "Enter node moniker: " NODE_MONIKER

printLine
echo -e "Node moniker:       ${GREEN}$NODE_MONIKER${NC}"
echo -e "Chain id:           ${GREEN}$CHAIN_ID${NC}"
echo -e "Chain demon:        ${GREEN}$CHAIN_DENOM${NC}"
echo -e "Binary version tag: ${GREEN}$BINARY_VERSION_TAG${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/chabanyknikita/cosmos_scripts/main/utils/install_dependies.sh)

printGREEN "4. Download and build binaries" && sleep 1

curl https://get.gitopia.com | bash
sudo mv /tmp/tmpinstalldir/git-remote-gitopia /usr/local/bin/

cd || return
rm -rf gitopia
git clone gitopia://Gitopia/gitopia
cd gitopia || return
git checkout v1.2.0
make install
gitopiad version

printGREEN "5. Initialize the node" && sleep 1

gitopiad config chain-id gitopia-janus-testnet-2
gitopiad init "$NODE_MONIKER" --chain-id gitopia-janus-testnet-2

printGREEN "6. Download genesis and addrbook" && sleep 1


curl -s https://server.gitopia.com/raw/gitopia/testnets/master/gitopia-janus-testnet-2/genesis.json.gz > ~/.gitopia/config/genesis.zip
gunzip -c ~/.gitopia/config/genesis.zip > ~/.gitopia/config/genesis.json
rm -rf ~/.gitopia/config/genesis.zip

curl -Ls https://snapshots-cosmos.mirror-reflection.com/cosmos-testnet/gitopia-testnet/addrbook.json > $HOME/.gitopia/config/addrbook.json

printGREEN "7. Add seeds" && sleep 1

SEEDS="e1ab0573d55ff92fad55d2929e353904f1bbe36f@rpc.gitopia-testnet.mirror-reflection.com:31656,3f472746f46493309650e5a033076689996c8881@gitopia-testnet.rpc.kjnodes.com:41659"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.gitopia/config/config.toml

printGREEN "8. Set pruning and minimum gaz price" && sleep 1

sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "10"|' \
  $HOME/.gitopia/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001utlore"|g' $HOME/.gitopia/config/app.toml
gitopiad tendermint unsafe-reset-all --home $HOME/.gitopia --keep-addr-book

printLine

printGREEN "9. Changing port if you have more one node or enter 0 for default port" && sleep 1

source <(curl -s https://raw.githubusercontent.com/chabanyknikita/cosmos_scripts/main/utils/change_port.sh) gitopia

printLine


printGREEN "10. Create a service" && sleep 1

sudo tee /etc/systemd/system/gitopiad.service > /dev/null << EOF
[Unit]
Description=Gitopia Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which gitopiad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF


printGREEN "11. Download snapshot and start service" && sleep 1

curl https://snapshots-cosmos.mirror-reflection.com/cosmos-testnet/gitopia-testnet/gitopia-janus-testnet-2_latest.tar | tar -xf - -C $HOME/.gitopia/data
sudo systemctl daemon-reload
sudo systemctl enable gitopiad
sudo systemctl start gitopiad

printLine
echo -e "Check logs:            ${GREEN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${GREEN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "You can add wallet and validator with :   https://github.com/MirrorReflectionTeam/cosmos_testnet_manuals/tree/main/gitopia#management"