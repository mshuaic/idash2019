from web3 import Web3
from solc import compile_standard
from pathlib import Path
import json


tmp = '''{
"language": "Solidity", 
"sources": {
  "%s": {
    "urls": ["%s"]}}, 
"settings": {
  "evmVersion": "homestead",
  "outputSelection": {
    "*": {
      "*": ["*"], 
      "": ["*"]}}}}
'''


class node:
    def __init__(self, ipcfile):
        self.web3 = Web3(Web3.IPCProvider(ipcfile))
        self.web3.eth.defaultAccount = self.web3.eth.accounts[0]

    def publish_sc(self, scfile, name):
        path = Path(scfile).resolve()
        global tmp
        sc = json.loads(tmp % (path.name, path))
        compiled_sol = compile_standard(sc, allow_paths=path.parent)
        contract_interface = compiled_sol['contracts'][path.name][name]
        w3 = self.web3
        w3.eth.defaultAccount = w3.eth.accounts[0]
        bytecode = contract_interface['evm']['bytecode']['object']
        tester = w3.eth.contract(
            abi=contract_interface['abi'], bytecode=bytecode)
        tx_hash = tester.constructor().transact()
        tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
        return tx_receipt, contract_interface

    def contract(self, tx_receipt, contract_interface):
        contract = self.web3.eth.contract(
            address=tx_receipt.contractAddress, abi=contract_interface['abi'])
        return contract

        # class smart_contract:
        # def __init__(self, )


# n = node("data/node0/geth.ipc")
# r, i = n.publish_sc('test.sol', 'test')
# # print(r, i)
# contract = n.contract(r, i)
# tx_hash = contract.functions.setVar(123).transact()
# n.web3.eth.waitForTransactionReceipt(tx_hash)
# print('contract var: {}'.format(contract.functions.getVar().call()))
