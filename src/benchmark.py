from pathlib import Path
import time
from blockchain import Blockchain
from logger import log
from tqdm import tqdm
import logging
import json
from utils import *
import sys
from localDB import LocalDB

BASELINE = 'baseline2'
LIBRARIES = ['Database.sol', 'Utils.sol',
             'GeneDrugLib.sol', 'Math.sol', 'StatLib.sol']
CONTRACT = f"{BASELINE}.sol"
CONTRACT_DIR = f"./contract/{BASELINE}"
LIBRARIES = list(
    map(lambda x: str(Path(CONTRACT_DIR).joinpath(x).resolve()), LIBRARIES))

CONTRACT = str(Path(CONTRACT_DIR).joinpath(CONTRACT).resolve())

DATA_DIR = '/home/mark/idash2019/data'
TRANSACTION_GAS = 21000

BENCHMARK_FILE = 'benchmarks.json'


def load_data(data_dir):
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
    return records


def possibleKeys(key):
    # not returning (*,*,*)
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


def toFile(fp, baseline, result, append=True):
    dic = josn.load(fp)
    dic[baseline] = result


def convert_remix_input(line):
    remix = []
    for item in line:
        if type(item) == str:
            remix.append(f"\"{item}\"")
        else:
            remix.append(str(item).lower())

    return ','.join(remix)


def main():
    size = 0
    if len(sys.argv) <= 1:
        size = None
    else:
        size = int(sys.argv[1])
    db = LocalDB()
    bc = Blockchain(blocking=True, libraries=LIBRARIES, contract=CONTRACT)
    records = load_data(DATA_DIR)[:size]

    insertion_time = 0
    totalGas = 0
    for record in tqdm(records):
        with open("insertion.log", 'a') as f:
            f.write("%s\n" % convert_remix_input(record))
        start = time.time()
        r = bc.insert(*record)
        insertion_time += (time.time() - start)
        totalGas += (r['gasUsed'] - TRANSACTION_GAS)
        db.insert(*record)

    # db.query("*", "*", "*")

    query_count = 0
    query_time = 0
    for key in tqdm(db.getKeys()):
        pks = possibleKeys(key)
        for pk in pks:
            start = time.time()
            bc.query(*pk)
            query_time += time.time() - start
            query_count += 1

    result = {
        "data size": len(records),
        'total insert time': insertion_time,
        "insert time per record": insertion_time / len(records),
        "total storage used (in gas)": totalGas,
        "storage per record": totalGas / len(records),
        "total query time": query_time,
        "query time per record": query_time / query_count
    }

    if not Path(BENCHMARK_FILE).exists():
        with open(BENCHMARK_FILE, 'w') as outfile:
            json.dump({}, outfile)

    with open(BENCHMARK_FILE, 'r+') as outfile:
        dic = json.load(outfile)
        dic[BASELINE] = result
        outfile.seek(0)
        json.dump(dic, outfile)


if __name__ == '__main__':
    main()
