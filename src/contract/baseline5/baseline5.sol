pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "./Utils.sol";
import "./Math.sol";

contract baseline5 {
    uint numObservations;
    uint numRelations;
    mapping (address => uint) numObservationsFromSenders;
    mapping (bytes32 => uint[]) relations;
    Stat[] statStorage;

    uint constant IMPROVED = 8;
    uint constant UNCHANGED = 9;
    uint constant DETERIORATED = 12;

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
    
    constructor() public{
        Stat memory EMPTY = Stat("",0,"",0,0,0,0,0,0);
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
	
        // statStorage index starts from 1
        uint index = numRelations+1;
	string memory variantNumber_str = Utils.uintToStr(variantNumber);
	bytes32 key = encodeKey(geneName, variantNumber_str, drugName);

	if (entryExists(geneName,variantNumber_str,drugName) == false) {
	    Stat memory r = buildStat(geneName,variantNumber,drugName, outcome, suspectedRelation, seriousSideEffect);
	    statStorage.push(r);
	    bytes32[8] memory keys = possibeKeys(geneName, variantNumber_str, drugName);
	    for (uint i=0;i<8;i++){
		relations[keys[i]].push(index);
	    }
	    numRelations++;
	} else {
	    index = relations[key][0];
            updateStat(statStorage[index], outcome,suspectedRelation,seriousSideEffect);
	}
	
        numObservations++;
        numObservationsFromSenders[msg.sender]++;
        
    }

    function buildStat(string memory geneName,
			   uint variantNumber,
                           string memory drugName,
                           string memory outcome, 
                           bool suspectedRelation,
                           bool seriousSideEffect) private pure returns(Stat memory){
	uint improvedCount = Utils.equals(outcome, IMPROVED) ? 1 : 0;
        uint unchangedCount = Utils.equals(outcome, UNCHANGED) ? 1 : 0;
        uint deterioratedCount = Utils.equals(outcome, DETERIORATED) ? 1 : 0;
        uint suspectedRelationCount = suspectedRelation ? 1 : 0;
        uint sideEffectCount = seriousSideEffect ? 1 : 0;
        return Stat(geneName,variantNumber,drugName,1,improvedCount,unchangedCount,deterioratedCount,suspectedRelationCount,sideEffectCount);
    }
	

    function updateStat(Stat storage old,
			    string memory outcome, 
			    bool suspectedRelation,
			    bool seriousSideEffect) private{
	old.totalCount += 1;
	if (Utils.equals(outcome, IMPROVED)){
	    old.improvedCount += 1;
	} else if (Utils.equals(outcome, UNCHANGED)) {
	    old.unchangedCount += 1;
	} else {
	    old.deterioratedCount += 1;
	}
	if (suspectedRelation) {
	    old.suspectedRelationCount += 1;
	}
	if (seriousSideEffect) {
	    old.sideEffectCount += 1;
	}				
    }

    function toGeneDrugRelation(Stat memory s) private pure returns(GeneDrugRelation memory) {
        return GeneDrugRelation(s.geneName, s.variantNumber, s.drugName, s.totalCount,
                                s.improvedCount, Math.div(s.improvedCount, s.totalCount),
                                s.unchangedCount, Math.div(s.unchangedCount, s.totalCount),
                                s.deterioratedCount, Math.div(s.deterioratedCount, s.totalCount),
                                s.suspectedRelationCount, Math.div(s.suspectedRelationCount, s.totalCount),
                                s.sideEffectCount, Math.div(s.sideEffectCount, s.totalCount));
    }
    
    function possibeKeys(string memory geneName, string memory variantNumber, string memory drugName)
	private pure returns(bytes32[8] memory){
	return [encodeKey("*","*",drugName), encodeKey("*",variantNumber,"*"),
		encodeKey("*",variantNumber,drugName), encodeKey(geneName,"*","*"),
		encodeKey(geneName,"*",drugName), encodeKey(geneName,variantNumber,"*"),
		encodeKey(geneName,variantNumber,drugName),encodeKey("*","*","*")];
    }

    function encodeKey(string memory geneName, string memory variantNumber, string memory drugName)
	private pure returns(bytes32) {
	return keccak256(abi.encodePacked(geneName,variantNumber,drugName));
    }    
   
    function query(
        string memory geneName,
        string memory variantNumber,
        string memory drug
    ) public view returns (GeneDrugRelation[] memory) {
	uint[] memory indexList = relations[encodeKey(geneName,variantNumber,drug)];
	GeneDrugRelation[] memory result = new GeneDrugRelation[](indexList.length);
	for (uint i=0;i<indexList.length;i++){
	    result[i] = toGeneDrugRelation(statStorage[indexList[i]]);
	}
	return result;
    }

    function entryExists(
                         string memory geneName,
                         string memory variantNumber,
                         string memory drugName
                         ) public view returns (bool){
	return relations[encodeKey(geneName,variantNumber,drugName)].length != 0;
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
