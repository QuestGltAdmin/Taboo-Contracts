const hre = require("hardhat");
const { getContractAddress } = require('@ethersproject/address')

async function main() {
  const [deployer] = await ethers.getSigners()
  console.log("deployer address", deployer.address);
  console.log("deployer balance ", (await deployer.getBalance())/1e18);

  // const transactionCount = await owner.getTransactionCount()
  // const futureAddress = getContractAddress({
  //   from: owner.address,
  //   nonce: transactionCount
  // })
  // console.log("Future addr", futureAddress);

  const NFTAuction = await hre.ethers.getContractFactory("NFTAuction");
  const nftAuction = await NFTAuction.deploy();

  await nftAuction.deployed();
  console.log("deployer balance ", (await deployer.getBalance())/1e18);
  console.log("Auction deployed to:", nftAuction.address);

  const LazyMint = await hre.ethers.getContractFactory("TabooNFT");
  const lazyMint = await LazyMint.deploy(deployer.address, "0xe7a9b31d284d524e87bf002d85acfcf5d1c9ea67");

  await lazyMint.deployed();
  console.log("deployer balance ", (await deployer.getBalance())/1e18);
  console.log("Lazy deployed to:", lazyMint.address);

  // initialize
  const tx = await nftAuction.initialize(lazyMint.address, 700);
  console.log("initialized", tx.hash);
  console.log("deployer balance ", (await deployer.getBalance())/1e18);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
