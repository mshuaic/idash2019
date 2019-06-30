# iDash2019 Track 1

## Menu
 - [Prerequisites](#prerequisites)
 - [Install go-ethereum](#install-go-ethereum)
 - [Setup Ethereum](#setup-ethereum)
 - [Connect Peers](#connect-peers)
 - [Smart Contract](#smart-contract)
 - [Useful Links](#useful-links)

## Prerequisites
 - Install *go*:  https://golang.org/dl/
	

## Install go-ethereum
 - Download go-ethereum  
 `git clone https://github.com/ethereum/go-ethereum`
 - Switch to the required the commit ([FAQ Q4](https://docs.google.com/document/d/1oGcCKYwqATImAm5hTjY5GjfHvUI0Gd_fpYRR8po4joA/edit)).  
 `git checkout 4bcc0a37`
 - Build *geth* and *bootnode*  
 `make all`

## Setup Ethereum
 - Default storage is in */home/ligi/.ethereum*
 - Create an account  
 `geth --datadir node0 account new`
 - Create a genesis file *genesis.json*. Replace *ADDRESS* with your account address.
	```
	{
	   "config": {
		   "chainId": 1,
		   "homesteadBlock": 0,
		   "eip155Block": 0,
		   "eip158Block": 0
	   },
	   "difficulty": "1",
	   "gasLimit": "0xffffffff",
	   "alloc": {
		   "ADDRESS": { "balance": "400000" }
	   }
	} 
	```
 - Initialize genesis block   
 `geth --datadir node0 init genesis.json`
 
 - Start Ethereum peer node  
 `geth --datadir node0 --networkid 1 --rpc --rpccorsdomain "*" --nodiscover --rpcapi "admin,db,eth,debug,miner,net,shh,txpool,personal,web3"`
 
## Connect Peers
 - Initialize genesis block in **different** location  
   `geth --datadir node1 init genesis.json`

 - Start Ethereum peer node with **different** ports and location  
   `geth --datadir node1 --networkid 1 --rpc --rpccorsdomain "*" --nodiscover --rpcapi "admin,db,eth,debug,miner,net,shh,txpool,personal,web3" --port 30304 --rpcport 8546`  
   It returns a enode link: *enode://xxxxxxx@127.0.0.1:30304*
 
 - rpc to the master node  
   `geth attach http://127.0.0.1:8545`  
   `admin.addPeers("enode://xxxxxxx@127.0.0.1:30304")`

 - Check if peer is connected  
   `admin.peers`

## Smart Contract
	TODO
 
## Useful Links
 - https://github.com/ethereum/go-ethereum
 - https://github.com/ethereum/go-ethereum/wiki/Private-network
 - https://geth.ethereum.org/interface/Command-Line-Options
 - https://github.com/ethereum/go-ethereum/wiki/Management-APIs
