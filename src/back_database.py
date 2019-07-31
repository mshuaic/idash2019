from node import node
from utils import attribute, outcome


class Database:
    def __init__(self, *args):
        self.proxy = node(*args)

   # args insert(geneName: str, variantNumber: int, drugName: str, outcome: str, relation: bool, sideEffect: bool):

    def insert(self, *args):
        self.proxy.insert(*args)

    def query(self, *args):
        return self.proxy.query(*args)


def test_main():
    db = Database()
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

    db.insert(*record)
    print(db.query("CETP", "*", "*"))
