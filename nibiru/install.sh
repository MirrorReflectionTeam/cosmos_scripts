#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/MirrorReflectionTeam/cosmos_scripts/main/utils/additional_commands.sh)

printLogo

CHAIN_ID="nibiru-itn-1"
CHAIN_DENOM="unibi"
BINARY_NAME="nibid"
BINARY_VERSION_TAG="v0.19.2"

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
rm -rf nibiru
git clone https://github.com/NibiruChain/nibiru.git
cd nibiru
git checkout v0.19.2
make install
nibid version

printGREEN "5. Initialize the node" && sleep 1

nibid config chain-id nibiru-itn-1
nibid init "$NODE_MONIKER" --chain-id nibiru-itn-1

printGREEN "6. Download genesis and addrbook" && sleep 1

curl -s https:/rpc.nibiru-testnet.mirror-reflection.com/genesis | jq -r .result.genesis > $HOME/.nibid/config/genesis.json
curl -s https://snapshots-cosmos.mirror-reflection.com/cosmos-testnet/nibiru-testnet/addrbook.json > $HOME/.nibid/config/addrbook.json

printGREEN "7. Add seeds" && sleep 1

SEEDS="3358dc86108195da5bc8fb6a33e90927f1fd97bb@rpc.nibiru-testnet.mirror-reflection.com:34656,df8596fa04abeff1d15b79570ff8c3eba85ed87a@35.185.8.9:26656,4a81486786a7c744691dc500360efcdaf22f0840@15.235.46.50:26656,c709cad9e11b315644fe8f1d2e90c03c5cba685c@34.91.8.241:26656,930b1eb3f0e57b97574ed44cb53b69fb65722786@144.76.30.36:15662,ad002a4592e7bcdfff31eedd8cee7763b39601e7@65.109.122.105:36656"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.nibid/config/config.toml

printGREEN "8. Set pruning and minimum gaz price" && sleep 1

sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "17"|' \
  $HOME/.nibid/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.025unibi"|g' $HOME/.nibid/config/app.toml
nibid tendermint unsafe-reset-all --home $HOME/.nibid --keep-addr-book

printLine

printGREEN "9. Changing port if you have more one node or enter 0 for default port" && sleep 1

source <(curl -s https://raw.githubusercontent.com/MirrorReflectionTeam/cosmos_scripts/main/utils/change_port.sh) nibid

printLine


printGREEN "10. Create a service" && sleep 1

sudo tee /etc/systemd/system/nibid.service > /dev/null << EOF
[Unit]
Description=Nibiru Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which nibid) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF


printGREEN "11. Download snapshot and start service" && sleep 1

curl https://snapshots-cosmos.mirror-reflection.com/cosmos-testnet/nibiru-testnet/nibiru-itn-1_latest.tar | tar -xf - -C $HOME/.nibid/data
sudo systemctl daemon-reload
sudo systemctl enable nibid
sudo systemctl start nibid

printLine
echo -e "Check logs:            ${GREEN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${GREEN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "You can add wallet and validator with :   https://github.com/MirrorReflectionTeam/cosmos_testnet_manuals/tree/main/nibiru#management"