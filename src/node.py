from interface import interface
from utils import attribute, outcome
from pathlib import Path

LIBRARIES = ['Database.sol', 'Utils.sol', 'GeneDrugLib.sol', 'Math.sol']
CONTRACT = 'test.sol'
INSERTION = ""


class Node:
    def __init__(self, libraries=LIBRARIES, contract=CONTRACT, **kwargs):
        self.interface = interface(**kwargs)
        self.interface.deploy_libraries(libraries)
        self.interface.publish(CONTRACT, Path(CONTRACT).stem)
        # self.contract = self.interface(tx_receipt, contract_interface)

    def insert(self, *args):
        self.interface.send("insertObservation", *args)

    def query(self, *args):
        return self.interface.retrieve("query", *args)

    def setBlocking(self, value):
        self.interface.blocking = value


def test():
    n = Node()
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
    print("\n")

    n.insert(*record)
    print(n.query("CETP", "*", "*"))
