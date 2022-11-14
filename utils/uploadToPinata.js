const pinataSDK = require("@pinata/sdk") // yarn add --dev @pinata/sdk
const path = require("path") //yarn add --dev path
const fs = require("fs")
require("dotenv").config()

const PINATA_API_KEY = process.env.PINATA_API_KEY || ""
const PINATA_API_SECRET = process.env.PINATA_API_SECRET || ""
const pinata = pinataSDK(PINATA_API_KEY, PINATA_API_SECRET)

async function storeImages(imageFilePath) {
    const fullImagesPath = path.resolve(imageFilePath) // 'pose if imageFilePath = ../images/randomNft/image.png, fullImagesPath = the full path
    const files = fs.readdirSync(fullImagesPath) //read the entire folder
    //console.log(files) // OUTPUT: ['pug.png', 'shiba-inu.png', 'st-bernard.png']
    let responses = []
    console.log("Uploading to IPFS")
    for (fileIndex in files) {
        const readableStreamForFile = fs.createReadStream(`${fullImagesPath}/${files[fileIndex]}`) //creatin' read stream cuz the images are a big objct
        try{
            const response = await pinata.pinFileToIPFS(readableStreamForFile) // pinFileToIPFS returns IpfsHash (the hash of the file)
            responses.push(response)
        } catch (error) {
            console.log(error)
        }
    }
    return { responses, files }
}

async function storeTokenUriMetadata(metadata) {
    try {
        const response = await pinata.pinJSONToIPFS(metadata)
        return response
    } catch (error) {
        console.log(error)
    }   
    return null
}

module.exports = { storeImages, storeTokenUriMetadata }


// 21:46:59 pin on ipfs
// 21:56:22