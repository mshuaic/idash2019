import time
import os
from pathlib import Path
from tqdm import tqdm
from utils import *
from blockchain import Blockchain
from localDB import LocalDB
import json

from logger import log
import logging
# log.setLevel(logging.DEBUG)
# log.setLevel(logging.ERROR)


data_dir = '/home/mark/idash2019/data'

TRANSACTION_GAS = 21000

BLOCKING = False


def load_contracts(contract_dir, suffix='.sol'):
    result = []
    with os.scandir(contract_dir) as it:
        # print(it)
        for entry in it:
            if Path(entry).suffix == suffix:
                result.append(Path(entry).absolute())
    return result


def load_data(size=None):
    # data_file = '../sample/data0.txt'
    files = fileReader(data_dir)
    data = []
    for path in files.getFilePathes():
        with open(path, 'r') as f:
            data += f.readlines()

    records = []
    for d in data:
        line = d.strip('\n')
        line = line.split('\t')
        record = [attribute()._type()[i](line[i]) for i in range(len(line))]
        records.append(record)
    return records[:size]


def possibleKeys(key):
    result = []
    size = len(key)
    for i in range(2**size):
        tmp = []
        for j in range(size):
            if i & (1 << j) == (1 << j):
                tmp.append(str(key[j]))
            else:
                tmp.append("*")
        result.append(tmp)
    return result[1:]


def benchmark(contract, size):
    contract_dir = f"./contract/{contract}"
    contracts = load_contracts(contract_dir)
    main_contract = f"{contract}.sol"
    main_contract = Path(contract_dir).joinpath(main_contract).resolve()
    contracts.remove(main_contract)
    records = load_data()[:size]

    bc = Blockchain(blocking=BLOCKING, libraries=contracts,
                    contract=main_contract, ipcfile='/home/mark/eth/node0/geth.ipc',
                    timeout=120)
    db = LocalDB()

    result = {}

    tx_hashs = []
    for record in tqdm(records):
        tx_hash = bc.insert(*record)
        db.insert(*record)
        tx_hashs.append(tx_hash)

    receipts = bc.wait_all(tx_hashs)

    totalGas = sum([r['gasUsed'] for r in receipts])

    result['Insertion Total'] = totalGas
    result['Insertion Average'] = totalGas // size
    # print(totalGas)

    totalGas = bc.estimateQueryGas("*", "*", "*")
    for key in tqdm(db.getKeys()):
        pks = possibleKeys(key)
        for pk in pks:
            totalGas += bc.estimateQueryGas(*pk)

    result['Query Total'] = totalGas
    result['Query Average'] = totalGas // (size*7+1)

    return result
    # benchmark = {}
    # benchmark[main_contract.stem] = result
    # return benchmark


def main():
    sizes = [100, 200, 400, 800, 1600, 3200]
    final = {s: {} for s in sizes}
    baselines = [f"baseline{i}" for i in [3, 4]]
    # print(final)
    for size in sizes:
        for baseline in baselines:
            final[size][baseline] = benchmark(baseline, size)

    with open('benchmark.json', 'w') as f:
        json.dump(final, f)


if __name__ == '__main__':
    main()
