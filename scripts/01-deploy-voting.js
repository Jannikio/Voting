const { network } = require('hardhat');

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();


    const voting = await deploy('Voting', {
        from: deployer,
        args: [deployer],
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    });
}