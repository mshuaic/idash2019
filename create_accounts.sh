#!/bin/bash

num_of_node=4
ACCOUNT_FOLDER=accounts
OUTPUT=accounts.txt

rm -r $ACCOUNT_FOLDER
mkdir $ACCOUNT_FOLDER
touch $ACCOUNT_FOLDER/$OUTPUT

for ((i=0; i < $num_of_node; i++))
do
    geth --datadir $ACCOUNT_FOLDER account new --password <(echo "") >> $ACCOUNT_FOLDER/$OUTPUT
done

files=($ACCOUNT_FOLDER/keystore/*)
addresses=(`cat ${files[*]} | jq -r '.address'`)


cat genesis.json | jq --arg key ${addresses[0]}  '.alloc = {($key) : { "balance": "0xffffffffffffffffff" }}' > genesis.json.tmp


for ((i=1; i < $num_of_node; i++))
do
      cat genesis.json | jq --arg key ${addresses[$i]}  '.alloc += {($key) : { "balance": "0xffffffffffffffffff" }}' > genesis.json.tmp
done

mv genesis.json.tmp genesis.json
