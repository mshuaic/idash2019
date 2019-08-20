import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import json
import sys
import os
import numpy as np


# set width of bar
barWidth = 0.25

plt.rcParams["figure.figsize"] = [9, 9]
plt.subplots_adjust(left=0.1, right=0.95, bottom=0.1,
                    top=0.95, wspace=0.3, hspace=0.3)


def draw(result, catalog, selection, unit):
    xlabels = list(result.keys())
    baselines = list(result[xlabels[0]])
    baselines.remove('baseline4')
    # print(f"draw: {baselines}")
    bars = [None] * len(baselines)

    # Set height
    for i in range(len(bars)):
        bars[i] = [result[xlabel][baselines[i]][catalog][selection]
                   for xlabel in xlabels]

    # Set position of bar on X axis
    r = [None] * len(baselines)
    r[0] = range(len(bars[0]))
    for i in range(1, len(r)):
        r[i] = [x + barWidth for x in r[i-1]]
    r[1] = [x + barWidth for x in r[0]]

    for i in range(len(baselines)):
        plt.bar(r[i], bars[i], width=barWidth, label=baselines[i])

    plt.xticks([r + barWidth * 0.5 * (len(baselines)-1)
                for r in range(len(bars[0]))], xlabels)

    plt.xlabel('number of records')
    plt.ylabel(unit)
    plt.title(f"{catalog} {selection}")

    plt.legend()


def main():
    with open(sys.argv[1], 'r') as f:
        result = json.load(f)

    xlabels = list(result.keys())
    baselines = list(result[xlabels[0]])
    catalogs = list(result[xlabels[0]][baselines[0]])
    selections = list(result[xlabels[0]][baselines[0]][catalogs[0]])

    for i, catalog in enumerate(catalogs):
        unit = result[xlabels[0]][baselines[0]][catalog]['Unit']
        selections = list(result[xlabels[0]][baselines[0]][catalog])
        selections.remove('Unit')
        for j, selection in enumerate(selections):
            plt.subplot(3, 3, 1+i*2+j)
            draw(result, catalog, selection, unit)
    plt.show()


if __name__ == '__main__':
    main()
