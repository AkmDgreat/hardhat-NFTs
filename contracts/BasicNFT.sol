// SPDX-License-Identifier: MIT

//yarn add --dev @openzeppelin/contracts

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

pragma solidity ^0.8.8;

contract BasicNFT is ERC721 {
    string public constant TOKEN_URI = "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";
    uint256 private s_tokenCounter;

    constructor() ERC721("Dogie", "DOG") {
        s_tokenCounter = 0;
    }

    function mintNft() public returns(uint256) {
        _safeMint(msg.sender, s_tokenCounter); // mint the token to msg.sender, ie. msg.sender will own this NFT
        s_tokenCounter++;
        return s_tokenCounter;
    }

    function tokenURI(uint256 /*tokenId*/) public view override returns (string memory) {
        return TOKEN_URI; //we are not using tokenId in this function (hence, the "unused function parameter" warning)
    }

    function getTokenCounter() public view returns(uint256) {
        return s_tokenCounter;
    }
}