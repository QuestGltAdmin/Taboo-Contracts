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

  // const NFTAuction = await hre.ethers.getContractFactory("NFTAuction");
  // const nftAuction = await NFTAuction.deploy();

  // await nftAuction.deployed();
  // console.log("deployer balance ", (await deployer.getBalance())/1e18);
  // console.log("Auction deployed to:", nftAuction.address);

  const LazyMint = await hre.ethers.getContractFactory("TabooMarketplace");
  const lazyMint = await LazyMint.deploy(deployer.address, "0xe7a9b31d284d524e87bf002d85acfcf5d1c9ea67");

  await lazyMint.deployed();
  console.log("deployer balance ", (await deployer.getBalance())/1e18);
  console.log("Lazy deployed to:", lazyMint.address);
  
  const NFTResale = await hre.ethers.getContractFactory("NFTResale");
  const nftResale = await NFTResale.deploy();

  await nftResale.deployed();
  console.log("deployer balance ", (await deployer.getBalance())/1e18);
  console.log("Resale deployed to:", nftResale.address);

  //  initialize
  const initialize = await nftResale.initialize(lazyMint.address);
  console.log("initialized", initialize.hash);
  console.log("deployer balance ", (await deployer.getBalance())/1e18);

  const setMarketplace= await lazyMint.setMarketplaceContract(nftResale.address); 
  console.log("set Marketplace", setMarketplace.hash);


}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
