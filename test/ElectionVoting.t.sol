// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ElectionVoting.sol";

contract ElectionVotingTest is Test {
    ElectionVoting election;
    address owner;
    address govtOfficial;
    address nonOfficial;
    address voter1;
    address voter2;
    address voter3;
    address nonVerifiedVoter;

    // Voter IDs for testing
    uint256 constant voterID1 = 1001;
    uint256 constant voterID2 = 1002;
    uint256 constant voterID3 = 1003;

    // Election duration in minutes and seconds
    uint256 electionDurationInMinutes = 10;
    uint256 electionDurationInSeconds = electionDurationInMinutes * 60;

    function setUp() public {
        // Set up test addresses
        owner = address(this);
        govtOfficial = vm.addr(1);
        nonOfficial = vm.addr(2);
        voter1 = vm.addr(3);
        voter2 = vm.addr(4);
        voter3 = vm.addr(5);
        nonVerifiedVoter = vm.addr(6);

        // Deploy the contract (owner is deployer)
        election = new ElectionVoting();

        // Add a government official by owner
        vm.prank(owner);
        election.addGovtOfficial(govtOfficial);

        // Use govtOfficial to add allowed voter IDs
        vm.prank(govtOfficial);
        election.addAllowedVoterID(voterID1);
        vm.prank(govtOfficial);
        election.addAllowedVoterID(voterID2);
        vm.prank(govtOfficial);
        election.addAllowedVoterID(voterID3);
    }

    // --- GovOfficial Management Tests ---

    function testAddGovtOfficialAsOwner() public {
        // Non-owner attempt should revert
        vm.prank(nonOfficial);
        vm.expectRevert("Ownable: caller is not the owner");
        election.addGovtOfficial(nonOfficial);

        // Owner adds official
        vm.prank(owner);
        election.addGovtOfficial(nonOfficial);
        assertTrue(election.isGovtOfficial(nonOfficial), "NonOfficial should now be a govt official");
    }

    function testRemoveGovtOfficial() public {
        // Remove existing official by owner
        vm.prank(owner);
        election.removeGovtOfficial(govtOfficial);
        assertFalse(election.isGovtOfficial(govtOfficial), "Govt official should be removed");

        // Re-add for later tests
        vm.prank(owner);
        election.addGovtOfficial(govtOfficial);
        assertTrue(election.isGovtOfficial(govtOfficial), "Govt official re-added");
    }

    // --- Voter Verification Tests ---

    function testVerifyVoterSuccess() public {
        // voter1 verifies using voterID1
        vm.prank(voter1);
        election.verifyVoter(voterID1);
        assertTrue(election.isVerifiedVoter(voter1), "voter1 should be verified");
    }

    function testVerifyVoterWithUnallowedIDReverts() public {
        // Attempt to verify using an ID that hasn't been added
        vm.prank(voter2);
        vm.expectRevert("ID is not recognized");
        election.verifyVoter(9999);
    }

    function testVerifyVoterDuplicateIDReverts() public {
        // voter1 verifies successfully with voterID1
        vm.prank(voter1);
        election.verifyVoter(voterID1);
        // Another call using same ID should revert
        vm.prank(voter2);
        vm.expectRevert("ID has already been used for verification");
        election.verifyVoter(voterID1);
    }

    // --- Election Start Tests ---

    function testStartElectionSuccess() public {
        vm.prank(owner);
        election.startElection(electionDurationInMinutes);

        (bool ongoing, uint256 endTime) = (election.electionOngoing(), election.electionEndTime());
        assertTrue(ongoing, "Election should be active");
        assertApproxEqAbs(endTime, block.timestamp + electionDurationInSeconds, 2);
    }

    function testStartElectionWhenActiveReverts() public {
        vm.prank(owner);
        election.startElection(electionDurationInMinutes);

        // Trying to start an election before previous one has ended should revert
        vm.prank(owner);
        vm.expectRevert("Election is already active");
        election.startElection(electionDurationInMinutes);

        // Fast forward past election end, then starting a new one should succeed.
        vm.warp(election.electionEndTime() + 1);
        vm.prank(owner);
        election.startElection(electionDurationInMinutes);
    }

    // --- Candidate Management Tests ---

    function testAddCandidatesSuccess() public {
        // Ensure candidates can be added when election is not active
        string[] memory candidateNames = new string[](2);
        candidateNames[0] = "Alice";
        candidateNames[1] = "Bob";
        vm.prank(owner);
        election.addCandidates(candidateNames);

        // Retrieve candidates and check names
        (string[] memory names, uint256[] memory indexes) = election.getCandidates();
        assertEq(names.length, 2, "There should be 2 candidates");
        assertEq(indexes[0], 1, "Index should be 1 based");
        assertEq(names[0], "Alice", "First candidate should be Alice");
    }

    function testAddCandidatesWhenElectionActiveReverts() public {
        // Start election
        vm.prank(owner);
        election.startElection(electionDurationInMinutes);

        // Attempt to add candidates during an active election should revert
        string[] memory candidateNames = new string[](1);
        candidateNames[0] = "Carol";
        vm.prank(owner);
        vm.expectRevert("Cannot add candidates during an active election");
        election.addCandidates(candidateNames);
    }

    // --- Voting Tests ---

    function testVoteSuccess() public {
        // Setup: add candidates and start election
        string[] memory candidateNames = new string[](2);
        candidateNames[0] = "Alice";
        candidateNames[1] = "Bob";
        vm.prank(owner);
        election.addCandidates(candidateNames);

        vm.prank(owner);
        election.startElection(electionDurationInMinutes);

        // Verify voter then vote
        vm.prank(voter1);
        election.verifyVoter(voterID1);
        // Vote for candidate 1 (1-based)
        vm.prank(voter1);
        election.vote(1);
    }

    function testVoteByNonVerifiedVoterReverts() public {
        // Setup candidates and start election
        string[] memory candidateNames = new string[](1);
        candidateNames[0] = "Alice";
        vm.prank(owner);
        election.addCandidates(candidateNames);
        vm.prank(owner);
        election.startElection(electionDurationInMinutes);

        // Attempt to vote without verifying
        vm.prank(voter1);
        vm.expectRevert("Voter not verified");
        election.vote(1);
    }

    function testVoteTwiceReverts() public {
        // Setup candidates and start election
        string[] memory candidateNames = new string[](1);
        candidateNames[0] = "Alice";
        vm.prank(owner);
        election.addCandidates(candidateNames);
        vm.prank(owner);
        election.startElection(electionDurationInMinutes);

        // Verify voter and vote
        vm.prank(voter1);
        election.verifyVoter(voterID1);
        vm.prank(voter1);
        election.vote(1);

        // Second vote attempt should revert
        vm.prank(voter1);
        vm.expectRevert("You have already voted");
        election.vote(1);
    }

    function testVoteWithInvalidCandidateNumberReverts() public {
        // Setup candidates and start election
        string[] memory candidateNames = new string[](1);
        candidateNames[0] = "Alice";
        vm.prank(owner);
        election.addCandidates(candidateNames);
        vm.prank(owner);
        election.startElection(electionDurationInMinutes);

        // Verify voter
        vm.prank(voter1);
        election.verifyVoter(voterID1);
        // Test candidate index of 0
        vm.prank(voter1);
        vm.expectRevert("Invalid candidate number");
        election.vote(0);

        // Test candidate index above candidate count
        vm.prank(voter1);
        vm.expectRevert("Invalid candidate number");
        election.vote(2);
    }

    // --- Get Votes and Leading Candidate Tests ---

    function testGetVotes() public {
        // Setup: Add candidates, start election, verify voters and vote.
        string[] memory candidateNames = new string[](2);
        candidateNames[0] = "Alice";
        candidateNames[1] = "Bob";
        vm.prank(owner);
        election.addCandidates(candidateNames);
        vm.prank(owner);
        election.startElection(electionDurationInMinutes);

        // voter1 votes for candidate 1; voter2 votes for candidate 2
        vm.prank(voter1);
        election.verifyVoter(voterID1);
        vm.prank(voter2);
        election.verifyVoter(voterID2);

        vm.prank(voter1);
        election.vote(1);
        vm.prank(voter2);
        election.vote(2);

        (, uint256[] memory voteCounts) = election.getVotes();
        assertEq(voteCounts[0], 1, "Alice should have 1 vote");
        assertEq(voteCounts[1], 1, "Bob should have 1 vote");
    }

    function testGetLeadingCandidateRevertsIfNoCandidates() public {
        vm.expectRevert("No candidates available");
        election.getLeadingCandidate();
    }

    function testGetLeadingCandidateSuccess() public {
        // Setup: Add candidates and vote, such that candidate 2 leads.
        string[] memory candidateNames = new string[](2);
        candidateNames[0] = "Alice";
        candidateNames[1] = "Bob";
        vm.prank(owner);
        election.addCandidates(candidateNames);
        vm.prank(owner);
        election.startElection(electionDurationInMinutes);

        // voter1 votes for candidate 1; voter2 and voter3 vote for candidate 2
        vm.prank(voter1);
        election.verifyVoter(voterID1);
        vm.prank(voter2);
        election.verifyVoter(voterID2);
        vm.prank(voter3);
        election.verifyVoter(voterID3);

        vm.prank(voter1);
        election.vote(1);
        vm.prank(voter2);
        election.vote(2);
        vm.prank(voter3);
        election.vote(2);

        (string memory leadingName, uint256 leadingCount) = election.getLeadingCandidate();
        assertEq(leadingName, "Bob", "Bob should be the leading candidate");
        assertEq(leadingCount, 2, "Leading candidate should have 2 votes");
    }

    // --- Election Reset Tests ---

    function testResetElectionRevertsIfNotEnoughTime() public {
        // Setup: Start an election, vote.
        string[] memory candidateNames = new string[](1);
        candidateNames[0] = "Alice";
        vm.prank(owner);
        election.addCandidates(candidateNames);
        vm.prank(owner);
        election.startElection(electionDurationInMinutes);

        vm.prank(voter1);
        election.verifyVoter(voterID1);
        vm.prank(voter1);
        election.vote(1);

        // Attempt to reset election before WEEK_DURATION passes should revert
        vm.prank(owner);
        vm.expectRevert("Reset not allowed yet");
        election.resetElection();
    }

    function testResetElectionSuccess() public {
        // Setup: Start election, vote, then fast-forward time, then reset.
        string[] memory candidateNames = new string[](2);
        candidateNames[0] = "Alice";
        candidateNames[1] = "Bob";
        vm.prank(owner);
        election.addCandidates(candidateNames);
        vm.prank(owner);
        election.startElection(electionDurationInMinutes);

        // Verify and vote
        vm.prank(voter1);
        election.verifyVoter(voterID1);
        vm.prank(voter1);
        election.vote(1);

        // Store the current election ID
        uint256 currentElectionId = election.electionId();

        // Fast-forward time to after election end and WEEK_DURATION.
        uint256 newTime = election.electionEndTime() + election.WEEK_DURATION() + 1;
        vm.warp(newTime);

        // Reset the election.
        vm.prank(owner);
        election.resetElection();

        // After reset, candidates array should be empty and voters cleared.
        (string[] memory names,) = election.getVotes();
        assertEq(names.length, 0, "Candidates should be reset to empty");
        // lastVotedElection for voter1 should be less than the current electionId (reset implicitly by new election).
        assertTrue(
            election.lastVotedElection(voter1) <= currentElectionId,
            "lastVotedElection should allow voting in new election"
        );
        // electionOngoing flag should be false.
        assertFalse(election.electionOngoing(), "Election should no longer be ongoing");
    }
}
