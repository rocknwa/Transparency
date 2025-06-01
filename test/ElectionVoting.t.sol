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

        // Use govtOfficial to add allowed voter IDs (hashed internally)
        vm.prank(govtOfficial);
        election.addAllowedVoterID(voterID1);
        vm.prank(govtOfficial);
        election.addAllowedVoterID(voterID2);
        vm.prank(govtOfficial);
        election.addAllowedVoterID(voterID3);
    }

    // --- GovOfficial Management Tests ---

    function testAddGovtOfficialAsOwner() public {
        // Non-owner attempt usd should revert
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
        vm.expectRevert(ElectionVoting.IdNotRecognized.selector);
        election.verifyVoter(9999);
    }

    function testVerifyVoterDuplicateIDReverts() public {
        // voter1 verifies successfully with voterID1
        vm.prank(voter1);
        election.verifyVoter(voterID1);
        // Another call using same ID should revert
        vm.prank(voter2);
        vm.expectRevert(ElectionVoting.IdAlreadyUsed.selector);
        election.verifyVoter(voterID1);
    }

    function testReverifySameVoterWithDifferentID() public {
        // voter1 verifies with voterID1
        vm.prank(voter1);
        election.verifyVoter(voterID1);
        assertTrue(election.isVerifiedVoter(voter1), "voter1 should be verified");

        // voter1 attempts to re-verify with voterID2 (should succeed since verifiedAddresses doesn't prevent re-verification)
        vm.prank(voter1);
        election.verifyVoter(voterID2);
        assertTrue(election.isVerifiedVoter(voter1), "voter1 should still be verified");
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
        vm.expectRevert(ElectionVoting.ElectionAlreadyActive.selector);
        election.startElection(electionDurationInMinutes);

        // Fast forward past election end, then starting a new one should succeed
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
        vm.expectRevert(ElectionVoting.CannotAddCandidatesDuringElection.selector);
        election.addCandidates(candidateNames);
    }

    function testAddEmptyCandidatesArray() public {
        // Attempt to add an empty candidate array
        string[] memory candidateNames = new string[](0);
        vm.prank(owner);
        election.addCandidates(candidateNames);

        // Verify candidates array is still empty
        (string[] memory names, uint256[] memory indexes) = election.getCandidates();
        assertEq(names.length, 0, "Candidates array should be empty");
        assertEq(indexes.length, 0, "Indexes array should be empty");
    }

    function testGetCandidatesWhenEmpty() public view {
        // Retrieve candidates when none exist
        (string[] memory names, uint256[] memory indexes) = election.getCandidates();
        assertEq(names.length, 0, "Candidates array should be empty");
        assertEq(indexes.length, 0, "Indexes array should be empty");
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
        vm.expectRevert(ElectionVoting.VoterNotVerified.selector);
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
        vm.expectRevert(ElectionVoting.AlreadyVoted.selector);
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
        vm.expectRevert(ElectionVoting.InvalidCandidateNumber.selector);
        election.vote(0);

        // Test candidate index above candidate count
        vm.prank(voter1);
        vm.expectRevert(ElectionVoting.InvalidCandidateNumber.selector);
        election.vote(2);
    }

    function testVoteWhenElectionNotOngoingReverts() public {
        // Setup candidates but don't start election
        string[] memory candidateNames = new string[](1);
        candidateNames[0] = "Alice";
        vm.prank(owner);
        election.addCandidates(candidateNames);

        // Verify voter
        vm.prank(voter1);
        election.verifyVoter(voterID1);

        // Attempt to vote when election is not ongoing should revert
        vm.prank(voter1);
        vm.expectRevert(ElectionVoting.ElectionNotActive.selector);
        election.vote(1);
    }

    function testVoteAfterElectionEndedReverts() public {
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

        // Fast-forward to after election end
        vm.warp(election.electionEndTime() + 1);

        // Attempt to vote after election has ended should revert
        vm.prank(voter1);
        vm.expectRevert(ElectionVoting.ElectionHasEnded.selector);
        election.vote(1);
    }

    function testMultipleVotesForSameCandidate() public {
        // Setup: add candidates and start election
        string[] memory candidateNames = new string[](2);
        candidateNames[0] = "Alice";
        candidateNames[1] = "Bob";
        vm.prank(owner);
        election.addCandidates(candidateNames);
        vm.prank(owner);
        election.startElection(electionDurationInMinutes);

        // Verify multiple voters
        vm.prank(voter1);
        election.verifyVoter(voterID1);
        vm.prank(voter2);
        election.verifyVoter(voterID2);
        vm.prank(voter3);
        election.verifyVoter(voterID3);

        // All voters vote for candidate 1 (Alice)
        vm.prank(voter1);
        election.vote(1);
        vm.prank(voter2);
        election.vote(1);
        vm.prank(voter3);
        election.vote(1);

        // Check vote counts
        (, uint256[] memory voteCounts) = election.getVotes();
        assertEq(voteCounts[0], 3, "Alice should have 3 votes");
        assertEq(voteCounts[1], 0, "Bob should have 0 votes");
    }

    // --- Get Votes and Leading Candidate Tests ---

    function testGetVotes() public {
        // Setup: Add candidates, start election, verify voters and vote
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
        vm.expectRevert(ElectionVoting.NoCandidatesAvailable.selector);
        election.getLeadingCandidate();
    }

    function testGetLeadingCandidateSuccess() public {
        // Setup: Add candidates and vote, such that candidate 2 leads
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
        // Setup: Start an election, vote
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
        vm.expectRevert(ElectionVoting.ResetNotAllowedYet.selector);
        election.resetElection();
    }

    function testResetElectionImmediatelyAfterEndReverts() public {
        // Setup: Start an election, vote
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

        // Fast-forward to just after election end
        vm.warp(election.electionEndTime() + 1);

        // Attempt to reset election immediately after end (before WEEK_DURATION) should revert
        vm.prank(owner);
        vm.expectRevert(ElectionVoting.ResetNotAllowedYet.selector);
        election.resetElection();
    }

    function testResetElectionSuccess() public {
        // Setup: Start election, vote, then fast-forward time, then reset
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

        // Fast-forward time to after election end and WEEK_DURATION
        uint256 newTime = election.electionEndTime() + election.WEEK_DURATION() + 1;
        vm.warp(newTime);

        // Reset the election
        vm.prank(owner);
        election.resetElection();

        // After reset, candidates array should be empty and voters cleared
        (string[] memory names,) = election.getVotes();
        assertEq(names.length, 0, "Candidates should be reset to empty");
        // lastVotedElection for voter1 should be less than or equal to the current electionId
        assertTrue(
            election.lastVotedElection(voter1) <= currentElectionId,
            "lastVotedElection should allow voting in new election"
        );
        // electionOngoing flag should be false
        assertFalse(election.electionOngoing(), "Election should no longer be ongoing");
    }

    // --- GovOfficial Management Tests ---
    function testOnlyOfficialModifierRevertsForNonOfficial() public {
        // Non-official tries to add a voter ID
        vm.prank(nonOfficial);
        vm.expectRevert(ElectionVoting.OnlyGovernmentOfficial.selector);
        election.addAllowedVoterID(9999);
    }

    // --- Get Votes and Leading Candidate Tests ---
    function testGetLeadingCandidateWithTiedVotes() public {
        // Setup: Add candidates, start election, and have voters create a tie
        string[] memory candidateNames = new string[](2);
        candidateNames[0] = "Alice";
        candidateNames[1] = "Bob";
        vm.prank(owner);
        election.addCandidates(candidateNames);
        vm.prank(owner);
        election.startElection(electionDurationInMinutes);

        // Voters verify and vote to create a tie (1 vote each)
        vm.prank(voter1);
        election.verifyVoter(voterID1);
        vm.prank(voter2);
        election.verifyVoter(voterID2);

        vm.prank(voter1);
        election.vote(1); // Alice gets 1 vote
        vm.prank(voter2);
        election.vote(2); // Bob gets 1 vote

        // Check leading candidate (should return the first candidate in case of a tie)
        (string memory leadingName, uint256 leadingCount) = election.getLeadingCandidate();
        assertEq(leadingName, "Alice", "Alice should be returned as first candidate in tie");
        assertEq(leadingCount, 1, "Leading candidate should have 1 vote");
    }

    // --- Script Deployment Test ---
    function testElectionVotingScriptDeployment() public {
        // Simulate script execution
        ElectionVoting newElection = new ElectionVoting();
        address testGovtOfficial = vm.addr(7); // New address for testing
        vm.prank(address(this)); // Simulate owner
        newElection.addGovtOfficial(testGovtOfficial);

        // Verify the deployment and configuration
        assertTrue(newElection.isGovtOfficial(testGovtOfficial), "Test official should be added");
        assertTrue(newElection.isGovtOfficial(address(this)), "Deployer should be a govt official");
    }

    // --- Fuzz Testing Election Duration ---
    function testFuzzElectionDuration(uint256 duration) public {
        vm.assume(duration < type(uint256).max / 60); // Avoid overflow
        vm.prank(owner);
        election.startElection(duration);
        assertEq(election.electionEndTime(), block.timestamp + duration * 60, "End time should match duration");
    }

    // --- Gas Usage Test
    function testVoteGasUsage() public {
        string[] memory candidateNames = new string[](1);
        candidateNames[0] = "Alice";
        vm.prank(owner);
        election.addCandidates(candidateNames);
        vm.prank(owner);
        election.startElection(electionDurationInMinutes);
        vm.prank(voter1);
        election.verifyVoter(voterID1);

        uint256 gasStart = gasleft();
        vm.prank(voter1);
        election.vote(1);
        uint256 gasUsed = gasStart - gasleft();
        emit log_uint(gasUsed); // Log gas usage for analysis
    }
}
