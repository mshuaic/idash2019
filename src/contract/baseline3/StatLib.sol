pragma solidity ^0.5.9;

import "./Utils.sol";

library StatLib {
    struct Stat {
        string geneName;
        uint variantNumber;
        string drugName;
        uint totalCount;
        uint improvedCount;
        uint unchangedCount;
        uint deterioratedCount;
        uint suspectedRelationCount;
        uint sideEffectCount;
    }

    /* function equal(Stat memory s0, Stat memory s1) internal pure returns(bool) { */
    /*     return ((s0.improvedCount == s1.improvedCount) && */
    /*             (s0.unchangedCount == s1.unchangedCount) && */
    /*             (s0.deterioratedCount == s1.deterioratedCount) && */
    /*             (s0.suspectedRelationCount == s1.suspectedRelationCount) && */
    /*             (s0.sideEffectCount == s1.sideEffectCount)); */
    /* } */

    function update(Stat memory s, string memory outcome,
                    bool suspectedRelation, bool seriousSideEffect)
        internal pure returns(Stat memory) {
        s.improvedCount += Utils.equals(outcome, "IMPROVED") ? 1 : 0;
        s.unchangedCount += Utils.equals(outcome, "UNCHANGED") ? 1 : 0;
        s.deterioratedCount += Utils.equals(outcome, "DETERIORATED") ? 1 : 0;
        s.suspectedRelationCount = suspectedRelation ? 1 : 0;
        s.sideEffectCount = seriousSideEffect ? 1 : 0;
        Stat memory stat = Stat(s.geneName, s.variantNumber,s.drugName, s.totalCount+1,s.improvedCount,s.unchangedCount,s.deterioratedCount,s.suspectedRelationCount,s.sideEffectCount);
        return stat;
    }
    
    function buildRelation(string memory geneName,
                           uint variantNumber,
                           string memory drugName,
                           string memory outcome, 
                           bool suspectedRelation,
                           bool seriousSideEffect) internal pure returns(bytes32, Stat memory){
        uint improvedCount = Utils.equals(outcome, "IMPROVED") ? 1 : 0;
        uint unchangedCount = Utils.equals(outcome, "UNCHANGED") ? 1 : 0;
        uint deterioratedCount = Utils.equals(outcome, "DETERIORATED") ? 1 : 0;
        uint suspectedRelationCount = suspectedRelation ? 1 : 0;
        uint sideEffectCount = seriousSideEffect ? 1 : 0;
        Stat memory stat = Stat(geneName,variantNumber,drugName,1,improvedCount,unchangedCount,deterioratedCount,suspectedRelationCount,sideEffectCount);
        return (keccak256(abi.encodePacked(geneName, variantNumber, drugName)), stat);
    }

}

