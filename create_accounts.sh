#!/bin/bash

num_of_node=4
ACCOUNT_FOLDER=accounts
OUTPUT=accounts.txt

mkdir $ACCOUNT_FOLDER
touch $ACCOUNT_FOLDER/$OUTPUT

for ((i=0; i < $num_of_node; i++))
do
    geth --datadir $ACCOUNT_FOLDER account new --password <(echo "") >> $ACCOUNT_FOLDER/$OUTPUT
done



