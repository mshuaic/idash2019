from node import node
from utils import attribute, outcome
from ast import literal_eval
import pytestpy


n = node()
libraries = ['Database.sol', 'Utils.sol', 'GeneDrugLib.sol', 'Math.sol']
n.deploy_libraries(libraries)

r, i = n.publish_sc('test.sol', 'test')

contract = n.contract(r, i)

data_file = '../sample/data0.txt'
with open(data_file, 'r') as f:
    buff = f.readlines()

line = buff[0].strip('\n')
line = line.split('\t')

record = [attribute()._type()[i](line[i]) for i in range(len(line))]
# print(record)
for r in record:
    if type(r) is str:
        print(f'"{r}"', end=", ", sep=', ')
    elif type(r) is bool:
        print(str(r).lower(), end=", ", sep=', ')
    else:
        print(r, end=", ", sep=', ')
print("\n\n")

tx_hash = contract.functions.insertObservation(*record).transact()
n.web3.eth.waitForTransactionReceipt(tx_hash)
print(contract.functions.query("CETP", "*", "*").call())
