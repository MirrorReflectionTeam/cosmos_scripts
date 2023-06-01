#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/MirrorReflectionTeam/cosmos_scripts/main/utils/additional_commands.sh)

printLogo

CHAIN_ID="banksy-testnet-2"
CHAIN_DENOM="upica"
BINARY_NAME="banksyd"
BINARY_VERSION_TAG="v1.0.0"

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
rm -rf composable-testnet
git clone https://github.com/notional-labs/composable-testnet.git
cd composable-testnet
git checkout v2.3.3-testnet2fork
make install
banksyd version

printGREEN "5. Initialize the node" && sleep 1

banksyd config chain-id banksy-testnet-2
banksyd init $NODE_MONIKER --chain-id banksy-testnet-2

printGREEN "6. Download genesis and addrbook" && sleep 1

curl -Ls https://rpc.composable-testnet.mirror-reflection.com/genesis | jq -r .result.genesis > $HOME/.defund/config/genesis.json
curl -s https://snapshots-cosmos.mirror-reflection.com/cosmos-testnet/composable-testnet/addrbook.json > $HOME/.defund/config/addrbook.json

printGREEN "7. Add seeds" && sleep 1

SEEDS="a35221ab84e836c05d5a4689c78322833523233f@rpc.composable-testnet.mirror-reflection.com:32656,3f472746f46493309650e5a033076689996c8881@composable-testnet.rpc.kjnodes.com:15959"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.defund/config/config.toml

printGREEN "8. Set pruning and minimum gaz price" && sleep 1

sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "10"|' \
  $HOME/.banksy/config/app.toml

sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0ppica\"|" $HOME/.banksy/config/app.toml

banksyd tendermint unsafe-reset-all --home $HOME/.banksy --keep-addr-book

printLine

printGREEN "9. Changing port if you have more one node or enter 0 for default port" && sleep 1

source <(curl -s https://raw.githubusercontent.com/MirrorReflectionTeam/cosmos_scripts/main/utils/change_port.sh) banksy

printLine


printGREEN "10. Create a service" && sleep 1

sudo tee /etc/systemd/system/banksyd.service > /dev/null << EOF
[Unit]
Description=Composable Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which banksyd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
WorkingDirectory=$HOME
[Install]
WantedBy=multi-user.target
EOF


printGREEN "11. Download snapshot and start service" && sleep 1

curl -L https://snapshots-cosmos.mirror-reflection.com/cosmos-testnet/composable-testnet/banksy-testnet-2_latest.tar | tar -xf - -C $HOME/.banksy/data
sudo systemctl daemon-reload
sudo systemctl enable banksyd
sudo systemctl start banksyd
sudo journalctl -u banksyd -f --no-hostname -o cat

printLine
echo -e "Check logs:            ${GREEN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${GREEN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "You can add wallet and validator with :   https://github.com/MirrorReflectionTeam/cosmos_testnet_manuals/tree/main/composable#management"