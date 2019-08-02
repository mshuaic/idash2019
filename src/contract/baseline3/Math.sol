pragma solidity ^0.5.9;

import "./Utils.sol";

library Math{
    uint constant precision = 6;
    uint constant e7 = 10**(precision);
    
    
    // unsafe division
    // truncates the remining digits
    function div(uint a, uint b) public pure returns(string memory){
        assert(a < (2**240));
        uint result = a * e7 / b;
        return result == 0 ? "0" : mock(result);
    }
    
    function uintToBytes(uint number) private pure returns(bytes memory) {
        return Utils.uintToBytes(number);
    }
    
    function mock(uint result) public pure returns (string memory){
        bytes memory integer = uintToBytes(result / e7);
        uint integer_size = bytes(integer).length;
        bytes memory output = new bytes(integer_size+precision+1);
        bytes memory tmp = uintToBytes(result);

        for(uint i=0;i<integer_size;i++){
            output[i] = integer[i];
        }
        output[integer_size] = bytes1(".");
        for(uint i=0;i<precision;i++){
            output[integer_size+i+1] = tmp[integer_size+i];
        }
        return string(output);
    }
    
}