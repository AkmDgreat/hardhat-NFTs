// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/* When we mint NFT, a Chainlink VRF will be triggered & we'll get a random no.
   Using this no., we'll get a random NFT: Pug (rare), Shiba Inu (less rare), or St. Bernard (common) 
   Users have to pay to mint an NFT
   The owner of contract can withdraw the ETH (ie. artist is paid)
*/

//yarn add --dev @chainlink/contracts

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error RandomIpfsNft__RangeOutOfBounds();
error RandomIpfsNft__NeedMoreEth();
error RandomIpfsNft__TransferFailed();

contract RandomIpfsNft is VRFConsumerBaseV2, ERC721URIStorage, Ownable{

    //Type declaration
    enum Breed {
        PUG,
        SHIBA_INU,
        ST_BERNARD
    }

    // Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    mapping(uint256 => address) public s_requestIdToSender;

    // NFT Variables
    uint256 s_tokenCounter;
    uint256 internal constant MAX_CHANCE_VALUE = 100;
    string[] internal s_dogTokenUris;
    uint256 internal i_mintFee;

    //Events
    event NftRequested(uint256 indexed requestId, address requester);
    event NftMinted(Breed dogBreed, address minter);

    constructor(address vrfCoordinatorV2, uint64 subscriptionId, bytes32 gasLane, uint32 callbackGasLimit, string[3] memory dogTokenUris, uint256 mintFee) 
    VRFConsumerBaseV2(vrfCoordinatorV2) 
    ERC721("Random Ipfs Nft", "RIN")
    {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_subscriptionId = subscriptionId;
        i_gasLane = gasLane;
        i_callbackGasLimit = callbackGasLimit;
        s_dogTokenUris = dogTokenUris;
        i_mintFee = mintFee;
    }

    function requestNft() public payable returns(uint256 requestId) {
        if (msg.value < i_mintFee) {
            revert RandomIpfsNft__NeedMoreEth();
        }
        requestId = i_vrfCoordinator.requestRandomWords(i_gasLane, i_subscriptionId, REQUEST_CONFIRMATIONS, i_callbackGasLimit, NUM_WORDS);
        s_requestIdToSender[requestId] = msg.sender;
        emit NftRequested(requestId, msg.sender);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override{
        // fullfillRandomWords is called by VRFChainlinkKeepers, so, inside this function, msg.sender refers to VRFChainlinkKeepers 
        address dogOwner = s_requestIdToSender[requestId];
        uint256 newTokenId = s_tokenCounter;
                                                           
        uint256 moddedRandomWord = randomWords[0] % MAX_CHANCE_VALUE; // 0 <= modOfRandomWord <= 99 //  [0,9] => we get a Pug // [10, 39] => Shiba Inu // [40, 99] => St. Bernard
        Breed dogBreed = getBreedFromModOfRandomWord(moddedRandomWord);
        s_tokenCounter += s_tokenCounter;
        _safeMint(dogOwner, newTokenId); 
        _setTokenURI(newTokenId, s_dogTokenUris[uint256(dogBreed)]); // typecasting dogBreed to uint256 //_setTokenURI is not a very gas efficient function
        emit NftMinted(dogBreed, dogOwner);
    }

    function withDraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) { 
            revert RandomIpfsNft__TransferFailed();
        }
    }

    function getBreedFromModOfRandomWord (uint256 moddedRandomWord) public pure returns (Breed) {
        uint256 cumulativeSum = 0;
        uint256[3] memory chanceArray = getChanceArray();
        for( uint256 i = 0; i < chanceArray.length; i++) {
            if(moddedRandomWord >= cumulativeSum && moddedRandomWord < cumulativeSum + chanceArray[i]) {
                return Breed(i);
            }
            cumulativeSum += chanceArray[i];
        }
        revert RandomIpfsNft__RangeOutOfBounds(); 
    }

    /* Working of for loop:
       chanceArray.length = 3
       let moddedRandomWord be 25 (we are 'posed to get SHIBA_INU)
       i = 0, cumulativeSum = 0
       (moddedRandomWord >= cumulativeSum) but (moddedRandomWord isnot< cumulativeSum + chanceArray[i]) // chanceArray[i] = 10
       so, "if" is skipped and now cumulativeSum = 0 + 10 
       i = 1, cumulativeSum = 10
       (moddedRandomWord >= cumulativeSum) and (moddedRandomWord < cumulativeSum + chanceArray[i]) // chanceArray[i] = 30
       "if" runs and Breed(1) = SHIBA_INU is returned 
    */

    function getChanceArray() public pure returns (uint256[3] memory) {
        return [10, 30, MAX_CHANCE_VALUE]; // [0,10] [11,30] [31, 100]
    }

    function getMintFee() public view returns(uint256) {
        return i_mintFee;
    }

    function getTokenUris(uint256 index) public view returns(string memory) {
        return s_dogTokenUris[index];
    }

    function getTokenCounter() public view returns(uint256) {
        return s_tokenCounter;
    }

}