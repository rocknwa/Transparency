// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ElectionVoting.sol"; // Adjust the import path to point to your contract

contract ElectionVotingTest is Test {
    ElectionVoting election;
    address owner;
    address govtOfficial;
    address voter1;
    address voter2;
    address voter3;
    address nonVerifiedVoter;
    uint256 constant testVoterID = 12345;
    uint256 constant anotherVoterID = 54321;
    uint256 constant anotherVoterID0 = 5432;

    // These constants mimic a typical election duration in minutes.
    uint256 electionDurationInMinutes = 10;
    uint256 electionDurationInSeconds = electionDurationInMinutes * 60;

    function setUp() public {
        // Use the first address as the owner (deployer)
        owner = address(this);
        // Create test addresses
        govtOfficial = vm.addr(1);
        voter1 = vm.addr(2);
        voter2 = vm.addr(3);
        voter2 = vm.addr(4);
        nonVerifiedVoter = vm.addr(5);

        // Deploy the ElectionVoting contract
        election = new ElectionVoting();

        // From owner, add a government official other than owner.
        vm.prank(owner);
        election.addGovtOfficial(govtOfficial);

        // From the government official, add two allowed voter IDs.
        vm.prank(govtOfficial);
        election.addAllowedVoterID(testVoterID);
        vm.prank(govtOfficial);
        election.addAllowedVoterID(anotherVoterID);
        vm.prank(govtOfficial);
        election.addAllowedVoterID(anotherVoterID0);

        // Pre-add candidates before starting the election.
        string[] memory candidates = new string[](2);
        candidates[0] = "Alice";
        candidates[1] = "Bob";
        vm.prank(owner);
        election.addCandidates(candidates);
    }

    function testGovtOfficialManagement() public {
        // Only owner can add or remove government officials.
        // Adding a new official from non-owner should revert.
        vm.prank(nonVerifiedVoter);
        vm.expectRevert("Ownable: caller is not the owner");
        election.addGovtOfficial(nonVerifiedVoter);

        // Remove a government official.
        vm.prank(owner);
        election.removeGovtOfficial(govtOfficial);
        bool removed = election.isGovtOfficial(govtOfficial);
        assertFalse(removed, "Govt official should be removed");

        // Re-add the official so that subsequent tests pass.
        vm.prank(owner);
        election.addGovtOfficial(govtOfficial);
        assertTrue(election.isGovtOfficial(govtOfficial), "Govt official should be added");
    }

    function testVoterVerification() public {
        // voter1 will verify using testVoterID.
        vm.prank(voter1);
        election.verifyVoter(testVoterID);
        bool verified = election.isVerifiedVoter(voter1);
        assertTrue(verified, "Voter should be verified");

        // Verify that duplicate verification with same ID fails.
        vm.prank(voter2);
        election.verifyVoter(anotherVoterID);
        vm.prank(voter1);
        vm.expectRevert("ID has already been used for verification");
        election.verifyVoter(testVoterID);
    }

    function testStartElection() public {
        // Starting election (only owner can do so).
        vm.prank(owner);
        election.startElection(electionDurationInMinutes);

        // Verify that the election is active.
        (bool ongoing, uint256 endTime) = (election.electionOngoing(), election.electionEndTime());
        assertTrue(ongoing, "Election should be ongoing");
        // endTime should be approximately now + electionDurationInSeconds.
        assertApproxEqAbs(endTime, block.timestamp + electionDurationInSeconds, 2);
    }

    function testCandidateAdditionRestriction() public {
        // Ensure that candidates cannot be added during an active election.
        vm.prank(owner);
        election.startElection(electionDurationInMinutes);
        string[] memory newCandidates = new string[](1);
        newCandidates[0] = "Carol";
        vm.prank(owner);
        vm.expectRevert("Cannot add candidates during an active election");
        election.addCandidates(newCandidates);
    }

    function testVotingAndLeadingCandidate() public {
        // Start an election.
        vm.prank(owner);
        election.startElection(electionDurationInMinutes);

        // Verify voters first.
        vm.prank(voter1);
        election.verifyVoter(testVoterID);
        vm.prank(voter2);
        election.verifyVoter(anotherVoterID);
        vm.prank(voter3);
        election.verifyVoter(anotherVoterID0);

        // voter1 votes for candidate 1 (Alice).
        vm.prank(voter1);
        election.vote(1);

        // voter2 votes for candidate 2 (Bob).
        vm.prank(voter2);
        election.vote(2);

         // voter2 votes for candidate 2 (Bob).
        vm.prank(voter3);
        election.vote(2);


        // Non verified voter should fail to vote.
        vm.prank(nonVerifiedVoter);
        vm.expectRevert("Voter not verified");
        election.vote(1);

        // Try voting twice from the same address.
        vm.prank(voter1);
        vm.expectRevert("You have already voted");
        election.vote(2);

        // Check votes.
        (, uint256[] memory voteCounts) = election.getVotes();
        assertEq(voteCounts[0], 1, "Alice should have 1 vote");
        assertEq(voteCounts[1], 2, "Bob should have 1 vote");

        // Determine leading candidate. In this tie scenario, our leading candidate function should return the first candidate with the highest vote.
        (string memory leadingName, uint256 leadingCount) = election.getLeadingCandidate();
        assertEq(leadingCount, 2, "Leading vote count should be 1");
        // The order may differ; both candidates have one vote. Depending on implementation,
        // leading candidate may be "Alice" (index 0) if the loop picks the first max.
        assertEq(leadingName, "Bob", "Leading candidate should be Bob");
    }

    function testResetElection() public {
        // Start an election and vote.
        vm.prank(owner);
        election.startElection(electionDurationInMinutes);
        vm.prank(voter1);
        election.verifyVoter(testVoterID);
        vm.prank(voter1);
        election.vote(1);

        // Fast forward time to after the election end and the reset period.
        uint256 newTime = election.electionEndTime() + election.WEEK_DURATION() + 1;
        vm.warp(newTime);

        // Reset the election.
        vm.prank(owner);
        election.resetElection();

        // After reset, candidates array should be empty and voters vote status reset.
        // It is not possible to read the candidates array length directly but we can call getVotes() which returns arrays.
        (string[] memory names, ) = election.getVotes();
        assertEq(names.length, 0, "Candidates should be reset");

        // Check that vote statuses have been reset.
        // Since the voters array is cleared during reset, verify that hasVoted mapping remains false for voter1.
        // (If voter1 votes again after a new election, the vote should proceed.)
        assertFalse(election.hasVoted(voter1), "Vote status should be reset");
        // Also, the election ongoing flag should be false.
        assertFalse(election.electionOngoing(), "Election should be ended after reset");
    }
}
// Note: The test cases are designed to cover the main functionalities of the ElectionVoting contract.