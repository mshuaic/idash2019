pragma solidity ^0.5.9;

import "./Utils.sol";

library Math{
    uint constant precision = 6;
    uint constant multiplier = 10**(precision);
    
    
    // unsafe division
    // truncates the remining digits
    function div(uint a, uint b) public pure returns(string memory){
        assert(a <= b);
        if (a == b) {
            return "1.000000";
        } else if (a == 0) {
            return "0";     
        }
        return truncate(a,b);
    }
    
    function uintToBytes(uint number) private pure returns(bytes memory) {
        return Utils.uintToBytes(number);
    }
    
    function truncate(uint a, uint b) private pure returns (string memory) {
        uint long_num = a * multiplier / b;
        bytes memory long_num_bytes = uintToBytes(long_num);
        return string(abi.encodePacked("0.",long_num_bytes));
    }
    
    // function mock(uint result) private pure returns (string memory){
    //     bytes memory integer = uintToBytes(result / multiplier);
    //     uint integer_size = bytes(integer).length;
    //     bytes memory output = new bytes(integer_size+precision+1);
    //     bytes memory tmp = uintToBytes(result);

    //     for(uint i=0;i<integer_size;i++){
    //         output[i] = integer[i];
    //     }
    //     output[integer_size] = bytes1(".");
    //     for(uint i=0;i<precision;i++){
    //         output[integer_size+i+1] = tmp[integer_size+i];
    //     }
    //     return string(output);
    // }
    
}