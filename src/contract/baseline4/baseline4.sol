pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "./Utils.sol";
import "./Math.sol";

contract baseline4 {

    
    uint numObservations;
    uint numRelations;
    mapping (address => uint) numObservationsFromSenders;
    mapping (bytes => StatIndex) relations;

    uint constant IMPROVED = 8;
    uint constant UNCHANGED = 9;
    uint constant DETERIORATED = 12;
    
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

    struct StatIndex {
	mapping (bytes => uint) index;
	GeneDrugRelation[] data;
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
        // uint index = numRelations+1;
	string memory variantNumber_str = Utils.uintToStr(variantNumber);
	bytes memory relationKey = encodeKey(geneName, variantNumber_str, drugName);

	if (entryExists(geneName,variantNumber_str,drugName) == false) {
	    GeneDrugRelation memory r = buildRelation(geneName,variantNumber,drugName, outcome, suspectedRelation, seriousSideEffect);
	    bytes[8] memory keys = possibeKeys(geneName, variantNumber_str, drugName);
	    for (uint i=0;i<8;i++){
		relations[keys[i]].data.push(r);
		relations[keys[i]].index[relationKey] = relations[keys[i]].data.length-1;
	    }
	    numRelations++;
	} else {
	    bytes[8] memory keys = possibeKeys(geneName, variantNumber_str, drugName);
	    for (uint i=0;i<8;i++){
		uint index = relations[keys[i]].index[relationKey];
		updateRelation(relations[keys[i]].data[index], outcome,suspectedRelation,seriousSideEffect);
	    }
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
	string memory suspectedRelationPercent = suspectedRelation ? "1.000000" : "0.000000";
        uint sideEffectCount = seriousSideEffect ? 1 : 0;
	string memory sideEffectPercent = seriousSideEffect ? "1.000000" : "0.000000";
	
	if (Utils.equals(outcome, IMPROVED)) {
	    return(GeneDrugRelation(geneName, variantNumber, drugName, 1, 1, "1.000000",
				    0,"0.000000",0,"0.000000",suspectedRelationCount,suspectedRelationPercent,
				    sideEffectCount,sideEffectPercent));
	} else if (Utils.equals(outcome, UNCHANGED)) {
	    return(GeneDrugRelation(geneName, variantNumber, drugName, 1, 0, "0.000000",
				    1,"1.000000",0,"0.000000",suspectedRelationCount,suspectedRelationPercent,
				    sideEffectCount,sideEffectPercent));
	} else{
	    return(GeneDrugRelation(geneName, variantNumber, drugName, 1, 0, "0.000000",
				    0,"0.000000",1,"1.000000",suspectedRelationCount,suspectedRelationPercent,
				    sideEffectCount,sideEffectPercent));
 	}	
    }

    function updateRelation(GeneDrugRelation storage old,
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
	old.improvedPercent = Math.div(old.improvedCount, old.totalCount);
	old.unchangedPercent = Math.div(old.unchangedCount, old.totalCount);
	old.deterioratedPercent = Math.div(old.deterioratedCount, old.totalCount);
	if (suspectedRelation) {
	    old.suspectedRelationCount += 1;
	}
	old.suspectedRelationPercent = Math.div(old.suspectedRelationCount, old.totalCount);
	if (seriousSideEffect) {
	    old.sideEffectCount += 1;
	}
	old.sideEffectPercent = Math.div(old.sideEffectCount, old.totalCount);
				
    }
    
    function possibeKeys(string memory geneName, string memory variantNumber, string memory drugName)
	private pure returns(bytes[8] memory){
	return [encodeKey("*","*",drugName), encodeKey("*",variantNumber,"*"),
		encodeKey("*",variantNumber,drugName), encodeKey(geneName,"*","*"),
		encodeKey(geneName,"*",drugName), encodeKey(geneName,variantNumber,"*"),
		encodeKey(geneName,variantNumber,drugName),encodeKey("*","*","*")];
    }

    function encodeKey(string memory geneName, string memory variantNumber, string memory drugName)
	private pure returns(bytes memory) {
	return abi.encodePacked(geneName,variantNumber,drugName);
    }    
   
    function query(
        string memory geneName,
        string memory variantNumber,
        string memory drug
    ) public view returns (GeneDrugRelation[] memory) {
	return relations[encodeKey(geneName,variantNumber,drug)].data;
    }

    function entryExists(
                         string memory geneName,
                         string memory variantNumber,
                         string memory drugName
                         ) public view returns (bool){
	bytes memory key = encodeKey(geneName, variantNumber, drugName);
	return relations[key].data.length != 0;
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
