//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

error Voting__NotOwner();
error Voting__NotRegistered();
error Voting__OutOfBound();
error Voting__RegistrationDeadlinePassed();
error Voting__NotRegisteredForProposal();
error Voting__AlreadyVoted();
error Voting__VotingHasNotStarted();
error Voting__VotingOver();
error Voting__SelfDelegationIllegal();
error Voting__DelegateMoreThanWeight();
error Voting__LoopInDelegation();
error Voting__VotingNotOver();
error Voting__ProposalAlreadyFinalized();

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
        if (msg.sender != owner) {
            revert Voting__NotOwner();
        }
        _;
    }

    modifier onlyRegistered() {
        if (voters[msg.sender].isRegistered != true) {
            revert Voting__NotRegistered();
        }
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
        if (_proposalIndex > proposals.length) {
            revert Voting__OutOfBound();
        }
        Proposal storage proposal = proposals[_proposalIndex];
        if (block.timestamp > proposal.registrationDeadline) {
            revert Voting__RegistrationDeadlinePassed();
        }
        Voter storage voter = voters[msg.sender];
        voter.registeredProposals[_proposalIndex] = true;
        emit ProposalRegistered(_proposalIndex, msg.sender);
    }

    function vote(uint256 _proposalIndex) public onlyRegistered {
        Voter storage voter = voters[msg.sender];
        if (voter.registeredProposals[_proposalIndex] != true) {
            revert Voting__NotRegisteredForProposal();
        }
        if (voter.voted == true) {
            revert Voting__AlreadyVoted();
        }

        Proposal storage proposal = proposals[_proposalIndex];
        if (block.timestamp < proposal.registrationDeadline) {
            revert Voting__VotingHasNotStarted();
        }
        if (block.timestamp > proposal.deadline) {
            revert Voting__VotingOver();
        }
        voter.voted = true;
        proposal.voteCount += voter.weight;

        emit Voted(_proposalIndex, msg.sender, voter.weight);
    }

    function delegate(address _to, uint256 _proposalIndex, uint256 _portion) public onlyRegistered {
        Voter storage sender = voters[msg.sender];
        if (sender.voted == true) {
            revert Voting__AlreadyVoted();
        }
        if (_to == msg.sender) {
            revert Voting__SelfDelegationIllegal();
        }
        if (sender.weight < _portion) {
            revert Voting__DelegateMoreThanWeight();
        }

        while (voters[_to].delegate != address(0) && voters[_to].delegate != msg.sender) {
            _to = voters[_to].delegate;
        }

        if (_to == msg.sender) {
            revert Voting__LoopInDelegation();
        }

        sender.weight -= _portion;
        sender.delegatedWeight[_proposalIndex] += _portion;

        Voter storage delegate_ = voters[_to];
        if(delegate_.voted) {
            proposals[_proposalIndex].voteCount += _portion;
        } else {
            delegate_.weight += _portion;
        }
    }

    function finalizeProposal(uint256 _proposalIndex) public onlyRegistered {
        if (_proposalIndex > proposals.length) {
            revert Voting__OutOfBound();
        }
        if (block.timestamp < proposals[_proposalIndex].deadline) {
            revert Voting__VotingNotOver();
        }
        if (proposals[_proposalIndex].finalized == true) {
            revert Voting__ProposalAlreadyFinalized();
        }
        proposals[_proposalIndex].finalized = true;
        emit ProposalFinalized(_proposalIndex);
    }

    function getProposalCount() public view returns (uint256) {
        return proposals.length;
    }

    function getProposal(uint256 _proposalIndex) public view returns (string memory name, uint256 voteCount, uint256 deadline, uint256 registrationDeadline, bool finalized) {
        if (_proposalIndex > proposals.length) {
            revert Voting__OutOfBound();
        }
        Proposal storage proposal = proposals[_proposalIndex];
        return (proposal.name, proposal.voteCount, proposal.deadline, proposal.registrationDeadline, proposal.finalized);
    }

    function getVoter(address _voter) public view returns (bool voted, bool isRegistered, uint256 weight, address delegateTo) {
        Voter storage voter = voters[_voter];
        return (voter.voted, voter.isRegistered, voter.weight, voter.delegate);
    }

    function isRegisteredForProposal(address _voter, uint256 _proposalIndex) public view returns (bool) {
        if (_proposalIndex > proposals.length) {
            revert Voting__OutOfBound();
        }
        return voters[_voter].registeredProposals[_proposalIndex];
    }
}