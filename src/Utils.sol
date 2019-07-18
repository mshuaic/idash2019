pragma solidity ^0.5.9;

library Utils {
    function uintToStr(uint v) internal pure returns (string memory){
        return string(uintToBytes(v));
    }
    
    function uintToBytes(uint _i) internal pure returns (bytes memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return bstr;
    }

    
    function strToUint(string memory s) internal pure returns (uint) {
        bytes memory b = bytes(s);
        uint result = 0;
        for (uint i = 0; i < b.length; i++) { // c = b[i] was not needed
            if (uint8(b[i]) >= 48 && uint8(b[i]) <= 57) {
                result = result * 10 + (uint8(b[i]) - 48); // bytes and int are not compatible with the operator -.
            }
        }
        return result; // this was missing
    }
    
    // @author Gonçalo Sá <goncalo.sa@consensys.net>
    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }
        return success;
    }
    
    function equals(string memory s0, string memory s1) internal pure returns (bool) {
        bytes memory _s0 = bytes(s0);
        bytes memory _s1 = bytes(s1);
        if(_s0.length != _s1.length){
            return false;
        }
        return equal(_s0,_s1);
        // assembly {
        //     equal := eq(keccak256(addr, len), keccak256(addr2, len))
        // }
    }
    
    function isStar(string memory str) internal pure returns(bool) {
        bytes memory tmp = bytes(str);
        if (tmp.length > 1){
            return false;
        }
        bytes1 star = "*";
        return tmp[0] == star;
    }


    // not safe
    function contains(bytes[] memory arr, bytes memory target) internal pure returns(int) {
        for (uint i=0;i<arr.length;i++) {
            if (keccak256(arr[i]) == keccak256(target)) {
                return int(i);
            }
        }
        return -1;
    } 
    
    function test(uint a) public pure returns(string memory) {
        return uintToStr(a);
    }
}
