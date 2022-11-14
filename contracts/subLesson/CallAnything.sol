//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

//first four bytes of a "function signature" will give the "function selector"
contract CallAnything{

    address public s_someAddress;
    uint256 public s_amount;
    string private constant signatureOfTransferFunction = "transfer(address,uint256)";

    function transfer(address someAddress, uint256 amount) public {
        s_someAddress = someAddress;
        s_amount = amount;
    }

    //This is one of the ways to get the function selector 
    function getSelector_1() public pure returns (bytes4 selector) {
        selector = bytes4(keccak256(bytes(signatureOfTransferFunction)));
    }

    function getCallData_1(address someAddress, uint256 amount) public pure returns (bytes memory) {
        return abi.encodeWithSelector(getSelector_1(), someAddress, amount);
    }

    // address(this) => address of this contact
    //inside this contract, call a  specific function 
    //As usual, call returns: bool success (whether the txn was successful or not)
    //we're typecasting bytes to bytes4 to get first 4 bytes of returnData
    function callTransferFunctionDirectly_1(address someAddress, uint256 amount) public returns (bytes4, bool) {
        (bool success, bytes memory returnData) = address(this).call(
            getCallData_1(someAddress, amount)
        );
        return (bytes4(returnData), success);    
    }

    function getCallData_2(address someAddress, uint256 amount) public pure returns (bytes memory) {
        return abi.encodeWithSignature(signatureOfTransferFunction, someAddress, amount);
    }

    function callTransferFunctionDirectly_2(address someAddress, uint256 amount) public returns (bytes4, bool){
        (bool success, bytes memory returnData) = address(this).call(
            getCallData_2(someAddress, amount)
        );
        return (bytes4(returnData), success);
    }
}