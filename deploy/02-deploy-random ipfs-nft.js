const { network, ethers } = require("hardhat")
const { developmentChains, networkConfig } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")
const { storeImages, storeTokenUriMetadata } = require("../utils/uploadToPinata")

const imagesLocation = "./images/randomNft/"
const FUND_AMOUNT = "1000000000000000000000" //10 LINK
let tokenUris = [
    'ipfs://QmaVkBn2tKmjbhphU7eyztbvSQU5EXDdqRyXZtRhSGgJGo',
    'ipfs://QmYQC5aGZu2PTH8XzbJrbDnvhj3gVs7ya33H9mqUNvST3d',
    'ipfs://QmZYmH5iDbD6v3U2ixoVAjioSzvWJszDzYdbeCLquGSpVm'
]
const metadataTemplate = {
    name: "",
    description: "",
    image: "",
    attributes: [
        {
            trait_type: "Cuteness",
            value: 100 // you can similarly add other "stats"
        }
    ]
}

module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId
    
    /* get the IPFS hashes of our images.
     1. With our own IPFS node
     2. Using Pinata 
     3. nft.storage */

     if (process.env.UPLOAD_TO_PINATA == "true") {
        tokenUris = await handleTokenUris()
     }
    
    let vrfCoordinatorV2Address, vrfCoordinatorV2Mock, subscriptionId
    if(developmentChains.includes(network.name)) {
        vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock") // mistake: NOT ethers.getContractAt("VRFCoordinatorV2Mock")
        vrfCoordinatorV2Address = vrfCoordinatorV2Mock.address
        const tx = await vrfCoordinatorV2Mock.createSubscription()
        const txReceit = await tx.wait(1)
        subscriptionId = txReceit.events[0].args.subId
        await vrfCoordinatorV2Mock.fundSubscription(subscriptionId, FUND_AMOUNT)
    } else{
        vrfCoordinatorV2Address = networkConfig[chainId].vrfCoordinatorV2
        subscriptionId = networkConfig[chainId].subscriptionId
    }

    log("--------------------")
    await storeImages(imagesLocation)    
    const args = [
        vrfCoordinatorV2Address, 
        subscriptionId, networkConfig[chainId].gasLane, 
        networkConfig[chainId].callbackGasLimit, 
        tokenUris,
        networkConfig[chainId].mintFee
    ]

    const RandomIpfsNft = await deploy("RandomIpfsNft", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1
    })
    log("--------------------")
    if(chainId !== 31337 && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(RandomIpfsNft.address, args)
    }
}

async function handleTokenUris() {
    tokenUris = []
    //1. Store the image in IPFS
    //2. Store the metadata in IPFS
    const {responses: imageUploadResponses, files} = await storeImages(imagesLocation) //responses is a list of responses from pinata
    for(imageUploadResponseIndex in imageUploadResponses) {
        let tokenUriMetadata = { ...metadataTemplate } // syntactic sugar: ... means to "unpack" the object
        // files = ['pug.png', 'shiba-inu.png', 'st-bernard.png']
        tokenUriMetadata.name = files[imageUploadResponseIndex].replace(".png", "") // eg: replace .png with nothing,  ie. pug.png => pug 
        tokenUriMetadata.description = `An adorable ${tokenUriMetadata.name} pup!`
        tokenUriMetadata.image = `ipfs://${imageUploadResponses[imageUploadResponseIndex].IpfsHash}`
        console.log(`Uploading ${tokenUriMetadata.name}...`)
        const metadataUploadResponse = await storeTokenUriMetadata(tokenUriMetadata)
        tokenUris.push(`ipfs://${metadataUploadResponse.IpfsHash}`)
    }
    console.log("Token URIs uploaded! They are:")
    console.log(tokenUris)
    return tokenUris
}

module.exports.tags = ["all", "randomipfs", "main"]

