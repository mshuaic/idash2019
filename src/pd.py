import pandas as pd
import os
from utils import *

input_dir = '/home/mark/sample/'


# freader = fileReader(input_dir, '.txt')
# buffs = freader.readfiles()
# # print(buffs.keys())
# col_names = attribute()._name()

# data = []
# for f in freader.getFilePathes():
#     data.append(pd.read_csv(f, sep='\t', names=col_names))

# data = pd.concat(data, ignore_index=True)


# print(data['geneName']['NAGS'])

data = database(input_dir).data

d = "dapsone"

# print(data[(data['geneName'] == 'NAGS') & (data['drugName'] == "dapsone")])
print(data.query())
# print(max(map(len, data['drugName'])))
# print(len(set(data['geneName'])))
# drugNameSize = 226
# geneName = 127


print(data[['geneName', 'variantNumber', 'drugName']])
# print(data.iloc[:1, 0:3])

# geneName = data['geneName']
# # print(geneName)
# variantNumber = data['variantNumber']
# drugName = data['drugName']

# print(len(set(zip(geneName, variantNumber, drugName))))
