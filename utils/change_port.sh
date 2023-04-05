#!/bin/bash


array_rpc=(26 27 28 29 30 31 32 33 34 35 36)
array_api=(13 14 15 16 17 18 19 20 21 22 23)
array_gRPC_web=(90 91 92 93 94 95 96 97 98 100)
array_laddr=(60 61 62 63 64 65 66 67 68 69 70)


echo "0->26657 rpc port"
echo "1->27657 rpc port"
echo "2->28657 rpc port"
echo "3->29657 rpc port"
echo "and so far..."
read -r -p "Choose port from 0 to 10: " PORT

sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${array_rpc[$PORT]}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${array_rpc[$PORT]}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${array_laddr[$PORT]}60\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${array_rpc[$PORT]}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${array_rpc[$PORT]}660\"%" $HOME/.defund/config/config.toml && sed -i.bak -e "s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${array_gRPC_web[$PORT]}90\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${array_gRPC_web[$PORT]}91\"%; s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${array_api[$PORT]}17\"%" $HOME/.defund/config/app.toml && sed -i.bak -e "s%^node = \"tcp://localhost:26657\"%node = \"tcp://localhost:${array_rpc[$PORT]}657\"%" $HOME/.$1/config/client.toml 