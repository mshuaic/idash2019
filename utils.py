from enum import IntEnum


class attribute(IntEnum):
    geneName = 0
    variantNumber = 1
    drugName = 2
    outcome = 3
    relation = 4
    sideEffect = 5


class outcome(IntEnum):
    UNCHANGED = 0
    IMPROVED = 1
    DETERIORATED = -1
