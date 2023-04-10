const { assert, expect } = require('chai');
const { ethers, network, deployments } = require('hardhat');
const { developmentChains } = require('../../helper-hardhat-config');

!developmentChains.includes(network.name)
    ? describe.skip
    : describe('Unit tests voting contract', function () {

        beforeEach(async function () {
            accounts = await ethers.getSigners();
            deployer = accounts[0];
            voter1 = accounts[1];
            votingContract = await ethers.getContract('Voting');
            voting = votingContract.connect(deployer);
        });

        describe ('Should add a Voter', async function () {
            it('emits a VoterAdded event', async function () {
                await expect(voting.addVoter(voter1.address, 1)).to.emit(voting, 'VoterAdded');
            });

            it ('only allows owner to add Voter', async function () {
                await expect(voting.connect(voter1).addVoter(voter1.address, 1)).to.be.revertedWith('Ownable: caller is not the owner');
            });
        });

        describe ('Create a new proposal', async function () {
            it('emits a ProposalCreated event', async function () {
                voting.addVoter(voter1.address, 1);
                voting.connect(voter1);
                await expect(voting.createProposal('Proposal 1', 1, 2)).to.emit(voting, 'ProposalCreated');
            });

            it ('only allows Registered Voters to create a proposal', async function () {
                await expect(voting.connect(voter1).createProposal('Proposal 1', 1, 2)).to.be.revertedWith('Voter is not registered');
            });
        });

        describe ('Register to vote for a proposal', async function () {});

        describe ('Vote for a proposal', async function () {});

        describe ('Delegate vote to another voter', async function () {});

        describe ('Finalize a proposal', async function () {});

        describe ('Get Proposal count', async function () {});

        describe ('Get Proposals', async function () {});

        describe ('Get Voter ', async function () {});

        describe ('Return if voter is registered to vote for a proposal', async function () {});
    });