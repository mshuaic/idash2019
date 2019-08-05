pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "./Database.sol";
import "./GeneDrugLib.sol";
import "./Utils.sol";
import "./Math.sol";
import "./StatLib.sol";

contract baseline3 {
    using Database for Database.Table;
    uint8 internal constant ATTRIBUTES_NUM = 3; 
    Database.Table[ATTRIBUTES_NUM] tables;
    /* GeneDrugLib.GeneDrug[] data; */
    
    uint numObservations;
    uint numRelations;
    mapping (address => uint) numObservationsFromSenders;
    mapping (bytes32 => uint[]) relations;
    GeneDrugRelation[] statStorage;
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
        GeneDrugRelation memory EMPTY = GeneDrugRelation("",0,"",0,0,"",0,"",0,"",0,"",0,"");
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
	    GeneDrugRelation memory r = buildRelation(geneName,variantNumber,drugName, outcome, suspectedRelation, seriousSideEffect);
	    statStorage.push(r);
	    bytes32[8] memory keys = possibeKeys(geneName, variantNumber_str, drugName);
	    for (uint i=0;i<8;i++){
		relations[keys[i]].push(index);
	    }
	    
	    numRelations++;
	} else {
	    index = relations[key][0];
            statStorage[index] = updateRelation(statStorage[index], outcome,suspectedRelation,seriousSideEffect);
	}
	
        numObservations++;
        numObservationsFromSenders[msg.sender]++;
        
    }

    function buildRelation(string memory geneName,
			   uint variantNumber,
                           string memory drugName,
                           string memory outcome, 
                           bool suspectedRelation,
                           bool seriousSideEffect) private pure returns(GeneDrugRelation memory){
        uint suspectedRelationCount = suspectedRelation ? 1 : 0;
	string memory suspectedRelationPercent = suspectedRelation ? "1.000000" : "0";
        uint sideEffectCount = seriousSideEffect ? 1 : 0;
	string memory sideEffectPercent = seriousSideEffect ? "1.000000" : "0";
	
	if (Utils.equals(outcome, "IMPROVED")) {
	    return(GeneDrugRelation(geneName, variantNumber, drugName, 1, 1, "1.000000",
				    0,"0",0,"0",suspectedRelationCount,suspectedRelationPercent,
				    sideEffectCount,sideEffectPercent));
	} else if (Utils.equals(outcome, "UNCHANGED")) {
	    return(GeneDrugRelation(geneName, variantNumber, drugName, 1, 0, "0",
				    1,"1.000000",0,"0",suspectedRelationCount,suspectedRelationPercent,
				    sideEffectCount,sideEffectPercent));
	} else{
	    return(GeneDrugRelation(geneName, variantNumber, drugName, 1, 0, "0",
				    0,"0",1,"1.000000",suspectedRelationCount,suspectedRelationPercent,
				    sideEffectCount,sideEffectPercent));
	}	
    }

    function updateRelation(GeneDrugRelation memory old,
			    string memory outcome, 
			    bool suspectedRelation,
			    bool seriousSideEffect) private pure returns(GeneDrugRelation memory){
	old.totalCount += 1;
    	old.improvedCount += Utils.equals(outcome, "IMPROVED") ? 1 : 0;
        old.unchangedCount += Utils.equals(outcome, "UNCHANGED") ? 1 : 0;
        old.deterioratedCount += Utils.equals(outcome, "DETERIORATED") ? 1 : 0;
        old.suspectedRelationCount += suspectedRelation ? 1 : 0;
        old.sideEffectCount += seriousSideEffect ? 1 : 0;
	return GeneDrugRelation(old.geneName, old.variantNumber, old.drugName, old.totalCount,
                                old.improvedCount, Math.div(old.improvedCount, old.totalCount),
                                old.unchangedCount, Math.div(old.unchangedCount, old.totalCount),
                                old.deterioratedCount, Math.div(old.deterioratedCount, old.totalCount),
                                old.suspectedRelationCount, Math.div(old.suspectedRelationCount, old.totalCount),
                                old.sideEffectCount, Math.div(old.sideEffectCount, old.totalCount));
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
	    result[i] = statStorage[indexList[i]];
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
