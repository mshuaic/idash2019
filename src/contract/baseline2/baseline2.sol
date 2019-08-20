pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "./Database.sol";
import "./GeneDrugLib.sol";
import "./Utils.sol";
import "./Math.sol";
import "./StatLib.sol";

contract baseline2 {
    using Database for Database.Table;
    uint8 internal constant ATTRIBUTES_NUM = 3; 
    Database.Table[ATTRIBUTES_NUM] tables;

    uint constant IMPROVED = 8;
    uint constant UNCHANGED = 9;
    uint constant DETERIORATED = 12;
    
    uint numObservations;
    uint numRelations;
    mapping (address => uint) numObservationsFromSenders;
    mapping (bytes => uint) relations;
    StatLib.Stat[] statStorage;

    struct GeneDrugRelation {
        string geneName;
        uint variantNumber;
        string drugName;
        uint totalCount;
        uint improvedCount;
        string improvedPercent;
        uint unchangedCount;
        string unchangedPercent;
        uint deterioratedCount;
        string deterioratedPercent;
        uint suspectedRelationCount;
        string suspectedRelationPercent;
        uint sideEffectCount;
        string sideEffectPercent;
    }
    
    constructor() public{
        StatLib.Stat memory EMPTY = StatLib.Stat("",0,"",0,0,0,0,0,0);
        statStorage.push(EMPTY); // make index starts from 1   
    }
    
    function insertObservation (
                                string memory geneName,
                                uint variantNumber,
                                string memory drugName,
                                string memory outcome,  // IMPROVED, UNCHANGED, DETERIORATED. This will always be capitalized, you don't have to worry about case.
                                bool suspectedRelation,
                                bool seriousSideEffect
                                ) public {
        bytes memory key;
        StatLib.Stat memory stat;
        uint index = 0;
        (key, stat) = StatLib.buildRelation(geneName,variantNumber,drugName,outcome,suspectedRelation,seriousSideEffect);
        if (relations[key] == 0) {
            statStorage.push(stat);
	    index = statStorage.length-1;
            relations[key] = index;
            numRelations++;
	    tables[uint(GeneDrugLib.attributes.geneName)].insert(geneName,index);
	    tables[uint(GeneDrugLib.attributes.variantNumber)].insert(Utils.uintToStr(variantNumber),index);
	    tables[uint(GeneDrugLib.attributes.drugName)].insert(drugName,index);
        } else {
            index = relations[key];
            update(statStorage[index], outcome,suspectedRelation,seriousSideEffect);
        }
        
        numObservations++;
        numObservationsFromSenders[msg.sender]++;

        
    }
    
    function update(StatLib.Stat storage s, string memory outcome,
                    bool suspectedRelation, bool seriousSideEffect) private{
	s.totalCount += 1;
        s.improvedCount += Utils.equals(outcome, IMPROVED) ? 1 : 0;
        s.unchangedCount += Utils.equals(outcome, UNCHANGED) ? 1 : 0;
        s.deterioratedCount += Utils.equals(outcome, DETERIORATED) ? 1 : 0;
        s.suspectedRelationCount += suspectedRelation ? 1 : 0;
        s.sideEffectCount += seriousSideEffect ? 1 : 0;
    }

    function query(GeneDrugLib.attributes attribute, string memory key) private view returns(uint[] memory) {
        return tables[uint(attribute)].query(key);
    }
    
    

        /** Takes geneName, variant-number, and drug-name as strings. A value of "*" for any name should be considered as a wildcard or alternatively as a null parameter.
        Returns: An array of GeneDrugRelation Structs which match the query parameters

        To clarify here are some example queries:
        query("CYP3A5", "52", "pegloticase") => An array of the one relation that matches all three parameters
        query("CYP3A5","52","*") => An array of all relations between geneName, CYP3A5, variant 52, and any drug
        query("CYP3A5","*","pegloticase") => An array of all relations between geneName, CYP3A5 and drug pegloticase, regardless of variant
        query("*","*","*") => An array of all known relations. 

        Note that capitalization matters. 
    */
    function query(
        string memory geneName,
        string memory variantNumber,
        string memory drug
    ) public view returns (GeneDrugRelation[] memory) {
        uint[] memory indexList;
        uint size;
        GeneDrugRelation[] memory result;
        if (Utils.isStar(geneName) && Utils.isStar(variantNumber) && Utils.isStar(drug)){
            result = new GeneDrugRelation[](numRelations);
            for (uint i=1;i<statStorage.length;i++) {
                result[i-1] = toGeneDrugRelation(statStorage[i]);
            }
            return result;
        }
        
        
        (indexList, size) = query_private(geneName,variantNumber,drug);
        result = new GeneDrugRelation[](size);

        for (uint i=0;i<size;i++) {
            result[i] = toGeneDrugRelation(statStorage[indexList[i]]);
        }
        return result;
    }

    function toGeneDrugRelation(StatLib.Stat memory s) private pure returns(GeneDrugRelation memory) {
        return GeneDrugRelation(s.geneName, s.variantNumber, s.drugName, s.totalCount,
                                s.improvedCount, Math.div(s.improvedCount, s.totalCount),
                                s.unchangedCount, Math.div(s.unchangedCount, s.totalCount),
                                s.deterioratedCount, Math.div(s.deterioratedCount, s.totalCount),
                                s.suspectedRelationCount, Math.div(s.suspectedRelationCount, s.totalCount),
                                s.sideEffectCount, Math.div(s.sideEffectCount, s.totalCount));
    }
     
    function query_private(
        string memory geneName,
        string memory variantNumber,
        string memory drugName) private view returns (uint[] memory, uint) {


        uint[] memory geneList = Utils.isStar(geneName) ? new uint[](0) : query(GeneDrugLib.attributes.geneName, geneName);
        uint[] memory variantList = Utils.isStar(variantNumber) ? new uint[](0) : query(GeneDrugLib.attributes.variantNumber, variantNumber);
        uint[] memory drugList = Utils.isStar(drugName) ? new uint[](0) : query(GeneDrugLib.attributes.drugName, drugName);
        /* uint[][] memory lists = [geneList, variantList, drugList]; */
        uint  shortestListIndex = Utils.shortestList([geneList, variantList, drugList]);
        return Utils.intersect([geneList, variantList, drugList], shortestListIndex);
    }
    
    function entryExists(
                         string memory geneName,
                         string memory variantNumber,
                         string memory drugName
                         ) public view returns (bool){
        if (numObservations == 0) {
            return false;
        }
        uint size;
        (,size) = query_private(geneName,variantNumber,drugName);
        return size > 0;
            
    }

    /** Return the total number of known relations, a.k.a. the number of unique geneName,-name, variant-number, drug-name pairs
     */
    function getNumRelations () public view returns(uint){
        return numRelations;
    }
    
    /** Return the total number of recorded observations, regardless of sender.
     */
    function getNumObservations() public view returns (uint) {
        return numObservations;
    }

    /** Takes: A wallet address.
        Returns: The number of observations recorded from the provided wallet address
     */
    function getNumObservationsFromSender(address sender) public view returns (uint) {
        return numObservationsFromSenders[sender];
    }

}
