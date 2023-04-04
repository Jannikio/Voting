//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Voting {
    struct Voter {
        bool voted;
        bool isRegistered;
        uint256 weight;
        address delegate;
        mapping(uint256 => uint256) delegatedWeight;
        mapping(uint256 => bool) registeredProposals;
    }

    struct Proposal {
        string name;
        uint256 voteCount;
        uint256 deadline;
        uint256 registrationDeadline;
        bool finalized;
    }

    address public owner;
    mapping (address => Voter) public voters;
    Proposal[] public proposals;

    event VoterAdded(address indexed _voter, uint256 _weight);
    event ProposalCreated(uint256 _proposalIndex, string _name, uint256 _deadline, uint256 _registrationDeadline);
    event ProposalRegistered(uint256 indexed _proposalIndex, address indexed _voter);
    event Voted(uint256 indexed _proposalIndex, address indexed _voter, uint256 _weight);
    event ProposalFinalized(uint256 indexed _proposalIndex);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyRegistered() {
        require(voters[msg.sender].isRegistered, "Only registered voters can call this function.");
        _;
    }

    function addVoter(address _voter, uint256 _weight) public onlyOwner {
        Voter storage voter = voters[_voter];
        voter.isRegistered = true;
        voter.weight = _weight;
        voter.voted = false;
        voter.delegate = address(0);

        emit VoterAdded(_voter, _weight);
    }

    function createProposal(string memory _name, uint256 _duration, uint256 _registrationDuration) public onlyRegistered {
        uint256 proposalIndex = proposals.length;
        proposals.push(Proposal({
            name: _name,
            voteCount: 0,
            deadline: block.timestamp + _duration,
            registrationDeadline: block.timestamp + _registrationDuration,
            finalized: false
        }));

        emit ProposalCreated(proposalIndex, _name, proposals[proposalIndex].deadline, proposals[proposalIndex].registrationDeadline);
    }

    function registerForProposal(uint256 _proposalIndex) public onlyRegistered {
        require(_proposalIndex < proposals.length, "Invalid proposal index.");
        Proposal storage proposal = proposals[_proposalIndex];
        require(block.timestamp < proposal.registrationDeadline, "Registration deadline has passed.");
        Voter storage voter = voters[msg.sender];
        voter.registeredProposals[_proposalIndex] = true;
        emit ProposalRegistered(_proposalIndex, msg.sender);
    }

    function vote(uint256 _proposalIndex) public onlyRegistered {
        Voter storage voter = voters[msg.sender];
        require(voter.registeredProposals[_proposalIndex], "You are not registered for this proposal.");
        require(!voter.voted, "Already voted.");

        Proposal storage proposal = proposals[_proposalIndex];
        require(block.timestamp > proposal.registrationDeadline, "Voting has not started.");
        require(block.timestamp < proposal.deadline, "Voting has ended.");
        voter.voted = true;
        proposal.voteCount += voter.weight;

        emit Voted(_proposalIndex, msg.sender, voter.weight);
    }

    function delegate(address _to, uint256 _proposalIndex, uint256 _portion) public onlyRegistered {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted.");
        require(_to != msg.sender, "Self-delegation is disallowed.");
        require(sender.weight >= _portion, "You cannot delegate more than your weight.");

        while (voters[_to].delegate != address(0) && voters[_to].delegate != msg.sender) {
            _to = voters[_to].delegate;
        }

        require (_to != msg.sender, "Found loop in delegation.");

        sender.weight -= _portion;
        sender.delegatedWeight[_proposalIndex] += _portion;

        Voter storage delegate = voters[_to];
        if(delegate.voted) {
            proposals[_proposalIndex].voteCount += _portion;
        } else {
            delegate.weight += _portion;
        }
    }

    function finalizeProposal(uint256 _proposalIndex) public onlyRegistered {
        require(_proposalIndex < proposals.length, "Invalid proposal index.");
        require(block.timestamp > proposals[_proposalIndex].deadline, "Voting has not ended.");
        require(!proposals[_proposalIndex].finalized, "Proposal has already been finalized.");
        proposals[_proposalIndex].finalized = true;
        emit ProposalFinalized(_proposalIndex);
    }

    function getProposalCount() public view returns (uint256) {
        return proposals.length;
    }

    function getProposal(uint256 _proposalIndex) public view returns (string memory name, uint256 voteCount, uint256 deadline, uint256 registrationDeadline, bool finalized) {
        require(_proposalIndex < proposals.length, "Invalid proposal index.");
        Proposal storage proposal = proposals[_proposalIndex];
        return (proposal.name, proposal.voteCount, proposal.deadline, proposal.registrationDeadline, proposal.finalized);
    }

    function getVoter(address _voter) public view returns (bool voted, bool isRegistered, uint256 weight, address delegate) {
        Voter storage voter = voters[_voter];
        return (voter.voted, voter.isRegistered, voter.weight, voter.delegate);
    }

    function isRegisteredForProposal(address _voter, uint256 _proposalIndex) public view returns (bool) {
        require(_proposalIndex < proposals.length, "Invalid proposal index.");
        return voters[_voter].registeredProposals[_proposalIndex];
    }
}