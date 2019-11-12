# iDash2019 Blockchain Track

## Competition Task 
 - [iDash 2019 Privacy and Security](http://www.humangenomeprivacy.org/2019/competition-tasks.html)
 


## Menu
 - [Prerequisites](#prerequisites)
 - [Setup Ethereum](#setup-ethereum)
 - [Implementation](#implementation)


## Prerequisites
 - Install [*go*](https://golang.org/dl/), [*solc*](https://solidity.readthedocs.io/en/latest/installing-solidity.html), [*go-ethereum*](https://github.com/ethereum/go-ethereum),[*jq*](https://stedolan.github.io/jq/)
	
## Setup Ethereum
	bash build.sh
	
It builds 4 Ethereum nodes, and only one of them will be mining with default 8 threads.


## Implementation
 - [GeneDrugRepo.sol](src/contract/GeneDrugRepo/GeneDrugRepo.sol): The final submitted solution
 - [benchmark.py](src/benchmark.py): benchmark tool
   - [draw.py](src/draw.py): benchmark plot drawing tool
   - [database.py](src/database.py): local database
   - [blockchain.py](src/blockchain.py): blockchain interface

