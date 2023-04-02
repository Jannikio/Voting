//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Voting {
    struct Voter {
        bool voted;
        bool isRegistered;
    }

    struct Proposal {
        uint256 voteCount;
    }

    constructor() {}
}