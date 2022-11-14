//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Encoding{
    function combineStrings() public pure returns(string memory){
        return string(abi.encodePacked("Yo human! ", "Have a great day!")); //Yo human! Have a great day!
        //we are typecasting bytes to string
        //note: in 0.8.12+, you can just do string.concat("Yo human! ", "Have a great day!") 
    }


    //We are converting 1 to bytes (or) we are encoding 1
    function encodeNumber() public pure returns (bytes memory) {
        bytes memory number = abi.encode(1);
        return number;
    }

    // we are encoding a string
    function encodeString() public pure returns (bytes memory) {
        bytes memory someString = abi.encode("some string");
        return someString;
        // someString =  0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000b736f6d6520737472696e67000000000000000000000000000000000000000000
    }

    function encodeStringPacked() public pure returns (bytes memory) {
        bytes memory someString = abi.encodePacked("some string");
        return someString;
        //just adobe acrobat compresses pdf, encodePacked compresses the massive bytes object
        // someString = 0x736f6d6520737472696e67
    }

    function encodeStringBytes() public pure returns (bytes memory) {
        bytes memory someString = bytes("some string");
        return someString;
        // someString = 0x736f6d6520737472696e67
        //This is the good ol' typecasting 
    }

    function decodeString() public pure returns (string memory) {
        string memory someString = abi.decode(encodeString(), (string));
        return someString;
        //encodeString() returns someString
        //"decode someString(a binary) to a string"
    }

    function multiEncode() public pure returns (bytes memory) {
        bytes memory someString = abi.encode("some string", "it's bigger!");
        return someString;
    }
    //instead of encoding one string at a time, we can encode multiple string at once
    
    function multiDecode() public pure returns (string memory, string memory) {
        (string memory someString, string memory someOtherString) = abi.decode(
            multiEncode(),
            (string, string)
        );
        return (someString, someOtherString);
    }
    //multiEncode() returns someString
    //"decode someString to 2 strings" (note: we hv used "pulling returns out of a function" syntax)

    function multiEncodePacked() public pure returns (bytes memory) {
        bytes memory someString = abi.encodePacked("some string", "it's bigger!");
        return someString;
    }
    //just like multiEncode() (but compressed)

    //This doesnt work: (cuz encodePacked() is ambiguous as its compressed)
    function multiDecodePacked() public pure returns (string memory) {
        string memory someString = abi.decode(multiEncodePacked(), (string));
        return someString;
    }

    function multiStringCastPacked() public pure returns (string memory) {
        string memory someString = string(multiEncodePacked());
        return someString; // good ol' typecastin'
    }
    
}