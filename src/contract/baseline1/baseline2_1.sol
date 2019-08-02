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
    /* GeneDrugLib.GeneDrug[] data; */
    
    uint numObservations;
    uint numRelations;
    mapping (address => uint) numObservationsFromSenders;
    mapping (bytes32 => uint) relations;
    StatLib.Stat[] statStorage;
    event debug(string);    
    
    // This structure is how the data should be returned from the query function.
    // You do not have to store relations this way in your contract, only return them.
    // geneName and drugName must be in the same capitalization as it was entered. E.g. if the original entry was GyNx3 then GYNX3 would be considered incorrect.
    // Percentage values must be acurrate to 6 decimal places and will not include a % sign. E.g. "35.123456"
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
        /* GeneDrugLib.GeneDrug memory ob = GeneDrugLib.GeneDrug(geneName,variantNumber,drugName,outcome,suspectedRelation,seriousSideEffect); */

        /* data.push(ob); */

        bytes32 key;
        StatLib.Stat memory stat;
        // statStorage index starts from 1
        uint index = numRelations+1;
        (key, stat) = StatLib.buildRelation(geneName,variantNumber,drugName,outcome,suspectedRelation,seriousSideEffect);
       
        // key is not in relations
        if (entryExists(geneName,variantNumber,drugName) == false) {
            statStorage.push(stat);
            relations[key] = index;
            numRelations++;
        } else {
            index = relations[key];
            statStorage[index] = StatLib.update(statStorage[index], outcome,suspectedRelation,seriousSideEffect);
        }

        tables[uint(GeneDrugLib.attributes.geneName)].insert(geneName,index);
        tables[uint(GeneDrugLib.attributes.variantNumber)].insert(Utils.uintToStr(variantNumber),index);
        tables[uint(GeneDrugLib.attributes.drugName)].insert(drugName,index);
        
        numObservations++;
        numObservationsFromSenders[msg.sender]++;

        
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
	return entryExists(geneName, Utils.strToUint(variantNumber), drugName);
    }

    function entryExists(string memory geneName,
			 uint variantNumber,
			 string memory drugName) private view returns(bool){
	bytes32 key=keccak256(abi.encodePacked(geneName, variantNumber, drugName));
	return relations[key] != 0;
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
