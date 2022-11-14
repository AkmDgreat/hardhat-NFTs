//SPDX-License-Identifier: MIT

/*
Instead of hosting the data on ipfs, we can host it directly on-chain
IPFS: pros: cheap
      cons: someone needs to pin the data
direct blockchain hosting: pros: decentralised
                           cons: pretty expensive
*/

/*
if price > X ETH -> happy face
if price < X ETH -> frown face
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "base64-sol/base64.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract DynamicNftSvg is ERC721 {
    uint256 private s_tokenCounter;
    string private s_lowImageURI;
    string private s_highImageURI;
    AggregatorV3Interface internal immutable i_priceFeed;
    mapping(uint256 => int256) public s_tokenIdToHighValue;
    string private constant base64EncodedSvgPrefix =
        "data:image/svg+xml;base64,";
    string private constant base64EncodedJsonPrefix =
        "data:application/json;base64,";

    event createdNFT(uint256 indexed tokenId, int256 highValue); 

    constructor(
        address priceFeedAddress,
        string memory lowSvg,
        string memory highSvg
    ) ERC721("Dynamic Svg Nft", "DSN") {
        s_tokenCounter = 0;
        s_lowImageURI = svgToImageURI(lowSvg);
        s_highImageURI = svgToImageURI(highSvg);
        i_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    //SVG is a bunch of code, so we need to convert it to imageURI
    //this conversion can be done by "https://base64.guru/converter/encode/url" or programatically
    //Luckily, someone has already made a contract to do this programatically
    //yarn add --dev base64-sol
    function svgToImageURI(string memory svg)
        public
        pure
        returns (string memory)
    {
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(svg)))
        );
        return
            string(abi.encodePacked(base64EncodedSvgPrefix, svgBase64Encoded));
    }

    function mintNft(int256 highValue) public {
        s_tokenIdToHighValue[s_tokenCounter] = highValue;
        _safeMint(msg.sender, s_tokenCounter); 
        s_tokenCounter++;
        emit createdNFT(s_tokenCounter, highValue);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for non-existent token"); // _exists is a function in ERC721
        //string memory imageURI = "hi";
        (, int256 price, , , ) = i_priceFeed.latestRoundData();
        string memory imageURI = s_lowImageURI;
        if (price >= s_tokenIdToHighValue[tokenId]) {
            imageURI = s_highImageURI;
        }

        string memory base64EncodedJson = Base64.encode(
            bytes(
                abi.encodePacked(
                    '{"name":"',
                    name(), // You can add whatever name here
                    '", "description":"An NFT that changes based on the Chainlink Feed", ',
                    '"attributes": [{"trait_type": "coolness", "value": 100}], "image":"',
                    imageURI,
                    '"}'
                )
            )
        );

        return string(abi.encodePacked(_baseURI(), base64EncodedJson));
    }
}
