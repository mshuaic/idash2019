from node import node
from utils import attribute, outcome
from ast import literal_eval

n = node("eth/node0/geth.ipc")
r, i = n.publish_sc('test.sol', 'test')
# print(r, i)
contract = n.contract(r, i)

data_file = 'data/Training_Data_1.txt'
with open(data_file, 'r') as f:
    buff = f.readlines()
    # print(buff)

line = buff[0].strip('\n')
line = line.split('\t')
# print(line)
line = [str(line[0]), int(line[1]), str(line[2]),
        str(line[3]), bool(line[4]), bool(line[5])]
print(line)
tx_hash = contract.functions.insertObservation(
    line[0], line[1], line[2], line[3], line[4], line[5]).transact()
n.web3.eth.waitForTransactionReceipt(tx_hash)
print('contract var: {}'.format(contract.functions.show().call()))
# tx_hash = contract.functions.push(2).transact()
# n.web3.eth.waitForTransactionReceipt(tx_hash)
# print('contract var: {}'.format(contract.functions.show().call()))
# tx_hash = contract.functions.insertObservation('bbb', 22, False).transact()
# n.web3.eth.waitForTransactionReceipt(tx_hash)
# print('contract var: {}'.format(contract.functions.show().call()))
