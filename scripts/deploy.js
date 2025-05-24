async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const TimedCrowdfunding = await ethers.getContractFactory("TimedCrowdfunding");
  const crowdfunding = await TimedCrowdfunding.deploy();

  await crowdfunding.deployed();

  console.log("TimedCrowdfunding contract deployed to:", crowdfunding.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
