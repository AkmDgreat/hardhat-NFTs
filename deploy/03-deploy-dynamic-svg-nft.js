const { network, ethers } = require("hardhat")
const { networkConfig } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")
const fs = require("fs")

module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    let chainId = network.config.chainId
    let ethUsdPriceFeedAddress

    if(chainId = 31337) {
        const ethUsdPriceFeed = await deployments.get("MockV3Aggregator") //await ethers.getContract("MockV3Aggregator")
        ethUsdPriceFeedAddress = ethUsdPriceFeed.address
    } else {
        ethUsdPriceFeedAddress = networkConfig[chainId].ethUsdPriceFeed
    }

    log("-----------------")

    const lowSvg = await fs.readFileSync("./images/dynamicNft/frown.svg", {encoding: "utf8"})
    const highSvg = await fs.readFileSync("./images/dynamicNft/happy.svg", {encoding: "utf8"})
    const args = [ethUsdPriceFeedAddress, lowSvg, highSvg]
    const DynamicNftSvg = await deploy("DynamicNftSvg", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1
    })

    if(chainId !== 31337 && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(DynamicNftSvg.address, args)
    }
}

module.exports.tags = ["all", "dynamicNft", "main"]