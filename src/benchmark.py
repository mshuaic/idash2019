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
    elapsed = 0
    for record in tqdm(records):
        tx_hash = bc.insert(*record)
        elapsed += timer(db.insert, *record)
        tx_hashs.append(tx_hash)

    receipts = bc.wait_all(tx_hashs)

    totalGas = sum([r['gasUsed'] for r in receipts])

    # Measured by gas
    result['Storage'] = {'Unit': 'gas',
                         'Total': totalGas, 'Average': totalGas // size}

    # Measured by time
    result['Insertion'] = {'Unit': 'second',
                           'Total': elapsed, 'Average': elapsed / size}

    query = {f"{i} *": 0 for i in range(4)}
    query['Unit'] = 'second'
    elapsed = timer(bc.query, "*", "*", "*")
    query["3 *"] = elapsed

    for key in tqdm(db.getKeys()):
        pks = possibleKeys(key)
        for i, pk in enumerate(pks):
            elapsed = timer(bc.query, *pk)
            if i in [0, 1, 3]:
                query["2 *"] += elapsed
            elif i in [2, 4, 5]:
                query["1 *"] += elapsed
            else:
                query["0 *"] += elapsed

    query["Average"] = query["2 *"] + \
        query["1 *"] + query["0 *"] + query["3 *"]

    query["Average"] /= (7 * size + 1)

    query["2 *"] /= (3*size)
    query["1 *"] /= (3*size)
    query["0 *"] /= size
    result['Query'] = query

    return result


def main():
    sizes = [100 * (2**i) for i in range(5)]
    # sizes = [100]
    final = {s: {} for s in sizes}
    baselines = [f"baseline{i}" for i in [2, 3, 4, 5]]
    for size in sizes:
        for baseline in baselines:
            print(baseline)
            final[size][baseline] = benchmark(baseline, size)
            with open('benchmark.json', 'w') as f:
                json.dump(final, f)


if __name__ == '__main__':
    main()
