// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title ElectionVoting - A secure election voting system following industry standards.
/// @notice This contract enables government officials to manage voter IDs, verify voters, nominate candidates, conduct voting, and reset elections securely.
/// @dev Inherits from OpenZeppelin's Ownable for restricted access control. Uses custom errors for gas-efficient error handling.
contract ElectionVoting is Ownable {
    // --- Custom Errors ---
    /// @notice Reverts when a non-government official attempts to call a restricted function.
    error OnlyGovernmentOfficial();
    /// @notice Reverts when an election is not currently active.
    error ElectionNotActive();
    /// @notice Reverts when an election has ended.
    error ElectionHasEnded();
    /// @notice Reverts when a voter ID has already been used for verification.
    error IdAlreadyUsed();
    /// @notice Reverts when an unrecognized voter ID is provided.
    error IdNotRecognized();
    /// @notice Reverts when attempting to start an election while one is active.
    error ElectionAlreadyActive();
    /// @notice Reverts when attempting to add candidates during an active election.
    error CannotAddCandidatesDuringElection();
    /// @notice Reverts when a non-verified voter attempts to vote.
    error VoterNotVerified();
    /// @notice Reverts when a voter attempts to vote more than once in an election.
    error AlreadyVoted();
    /// @notice Reverts when an invalid candidate number is provided.
    error InvalidCandidateNumber();
    /// @notice Reverts when attempting to reset an election before the required waiting period.
    error ResetNotAllowedYet();
    /// @notice Reverts when no candidates are available for vote tallying.
    error NoCandidatesAvailable();

    // --- Constants ---
    /// @notice Duration (2 weeks) to wait after an election ends before it can be reset.
    uint256 public constant WEEK_DURATION = 2 weeks;

    // --- State Variables ---
    /// @notice Timestamp when the current election ends.
    uint256 public electionEndTime;
    /// @notice Indicates whether an election is currently active.
    bool public electionOngoing;
    /// @notice Tracks the current election ID to prevent double voting.
    uint256 public electionId;
    /// @notice Maps hashed voter IDs to their approval status for voting eligibility.
    mapping(bytes32 => bool) private allowedVoterIDHashes;
    /// @notice Tracks whether a hashed voter ID has been used for verification.
    mapping(bytes32 => bool) private usedIDHashes;
    /// @notice Maps addresses to their voter verification status.
    mapping(address => bool) public verifiedAddresses;
    /// @notice Maps addresses to their government official status.
    mapping(address => bool) public govtOfficials;
    /// @notice Maps addresses to the election ID in which they last voted.
    mapping(address => uint256) public lastVotedElection;
    /// @notice Array of candidates in the current election.
    Candidate[] public candidates;

    // --- Data Structures ---
    /// @notice Represents a candidate with their name and vote count.
    struct Candidate {
        string name; // Candidate's name
        uint256 voteCount; // Number of votes received
    }

    // --- Events ---
    /// @notice Emitted when a new government official is added.
    event GovtOfficialAdded(address indexed official);
    /// @notice Emitted when a government official is removed.
    event GovtOfficialRemoved(address indexed official);
    /// @notice Emitted when a voter ID is added to the allowed list.
    event VoterIdAdded(bytes32 indexed voterIdHash);
    /// @notice Emitted when a voter is verified.
    event VoterVerified(address indexed voter, bytes32 voterIdHash);
    /// @notice Emitted when an election is started.
    event ElectionStarted(uint256 indexed endTime);
    /// @notice Emitted when a candidate is added.
    event CandidateAdded(string candidateName);
    /// @notice Emitted when a vote is cast.
    event Voted(address indexed voter, uint256 candidateIndex);
    /// @notice Emitted when the election is reset.
    event ElectionReset();

    // --- Constructor ---
    /// @notice Initializes the contract, setting the deployer as the owner and a government official.
    /// @dev Automatically grants government official status to the deployer via the Ownable constructor.
    constructor() {
        govtOfficials[msg.sender] = true; // Deployer is the initial government official
    }

    // --- Modifiers ---
    /// @notice Restricts function access to government officials only.
    /// @dev Reverts with OnlyGovernmentOfficial if the caller is not a government official.
    modifier onlyOfficial() {
        if (!govtOfficials[msg.sender]) revert OnlyGovernmentOfficial();
        _;
    }

    /// @notice Ensures the election is active and has not ended.
    /// @dev Reverts with ElectionNotActive if no election is ongoing, or ElectionHasEnded if the election has expired.
    modifier electionActive() {
        if (!electionOngoing) revert ElectionNotActive();
        if (block.timestamp >= electionEndTime) revert ElectionHasEnded();
        _;
    }

    // --- View Functions ---
    /// @notice Checks if an address is a government official.
    /// @param _official Address to check.
    /// @return True if the address is a government official, false otherwise.
    function isGovtOfficial(address _official) public view returns (bool) {
        return govtOfficials[_official];
    }

    /// @notice Checks if an address is a verified voter.
    /// @param _voter Address to check.
    /// @return True if the address is verified, false otherwise.
    function isVerifiedVoter(address _voter) public view returns (bool) {
        return verifiedAddresses[_voter];
    }

    // --- Administration Functions ---
    /// @notice Adds a government official who can manage voter IDs.
    /// @dev Restricted to the contract owner. Emits GovtOfficialAdded event.
    /// @param _official Address of the new government official.
    function addGovtOfficial(address _official) external onlyOwner {
        govtOfficials[_official] = true; // Grant official status
        emit GovtOfficialAdded(_official);
    }

    /// @notice Removes a government official.
    /// @dev Restricted to the contract owner. Emits GovtOfficialRemoved event.
    /// @param _official Address of the official to remove.
    function removeGovtOfficial(address _official) external onlyOwner {
        govtOfficials[_official] = false; // Revoke official status
        emit GovtOfficialRemoved(_official);
    }

    /// @notice Adds a voter ID to the allowed list for verification.
    /// @dev Restricted to government officials. Hashes the ID and emits VoterIdAdded event.
    /// @param _id The voter ID to allow.
    function addAllowedVoterID(uint256 _id) external onlyOfficial {
        bytes32 idHash = keccak256(abi.encodePacked(_id)); // Hash the voter ID for privacy
        allowedVoterIDHashes[idHash] = true; // Mark as allowed
        emit VoterIdAdded(idHash);
    }

    /// @notice Verifies a voter using their ID.
    /// @dev Hashes the ID and checks against allowed and used IDs. Emits VoterVerified event.
    /// @param _id The voter ID to verify.
    function verifyVoter(uint256 _id) external {
        bytes32 idHash = keccak256(abi.encodePacked(_id)); // Hash the voter ID
        if (usedIDHashes[idHash]) revert IdAlreadyUsed(); // Ensure ID hasn't been used
        if (!allowedVoterIDHashes[idHash]) revert IdNotRecognized(); // Ensure ID is allowed

        verifiedAddresses[msg.sender] = true; // Mark caller as verified
        usedIDHashes[idHash] = true; // Mark ID as used
        emit VoterVerified(msg.sender, idHash);
    }

    /// @notice Starts an election with a specified duration.
    /// @dev Restricted to the owner. Increments electionId and sets election state. Emits ElectionStarted event.
    /// @param _durationInMinutes Duration of the election in minutes.
    function startElection(uint256 _durationInMinutes) external onlyOwner {
        if (electionOngoing && block.timestamp < electionEndTime) revert ElectionAlreadyActive(); // Prevent starting during active election
        uint256 duration = _durationInMinutes * 60; // Convert minutes to seconds
        electionEndTime = block.timestamp + duration; // Set end time
        electionOngoing = true; // Mark election as active
        electionId += 1; // Increment election ID for new voting session
        emit ElectionStarted(electionEndTime);
    }

    /// @notice Adds multiple candidates before an election starts.
    /// @dev Restricted to the owner. Cannot be called during an active election. Emits CandidateAdded for each candidate.
    /// @param _candidateNames Array of candidate names to add.
    function addCandidates(string[] calldata _candidateNames) external onlyOwner {
        if (electionOngoing) revert CannotAddCandidatesDuringElection(); // Prevent adding during active election
        for (uint256 i = 0; i < _candidateNames.length; i++) {
            candidates.push(Candidate({name: _candidateNames[i], voteCount: 0})); // Add candidate with zero votes
            emit CandidateAdded(_candidateNames[i]);
        }
    }

    /// @notice Retrieves the list of candidates and their 1-based indexes.
    /// @return candidateNames Array of candidate names.
    /// @return indexes Array of 1-based candidate indexes.
    function getCandidates() external view returns (string[] memory candidateNames, uint256[] memory indexes) {
        candidateNames = new string[](candidates.length); // Initialize names array
        indexes = new uint256[](candidates.length); // Initialize indexes array
        for (uint256 i = 0; i < candidates.length; i++) {
            candidateNames[i] = candidates[i].name; // Copy candidate names
            indexes[i] = i + 1; // Assign 1-based index
        }
    }

    /// @notice Casts a vote for a candidate specified by a 1-based index.
    /// @dev Requires an active election and verified voter. Emits Voted event.
    /// @param _candidateNumber The 1-based index of the candidate to vote for.
    function vote(uint256 _candidateNumber) external electionActive {
        if (!verifiedAddresses[msg.sender]) revert VoterNotVerified(); // Ensure voter is verified
        if (lastVotedElection[msg.sender] >= electionId) revert AlreadyVoted(); // Prevent double voting
        lastVotedElection[msg.sender] = electionId; // Record voter's participation

        if (_candidateNumber == 0 || _candidateNumber > candidates.length) revert InvalidCandidateNumber(); // Validate candidate number

        uint256 candidateIndex = _candidateNumber - 1; // Convert to 0-based index
        candidates[candidateIndex].voteCount += 1; // Increment vote count

        emit Voted(msg.sender, candidateIndex);
    }

    /// @notice Retrieves candidate names and their current vote counts.
    /// @return candidateNames Array of candidate names.
    /// @return voteCounts Array of corresponding vote counts.
    function getVotes() external view returns (string[] memory candidateNames, uint256[] memory voteCounts) {
        candidateNames = new string[](candidates.length); // Initialize names array
        voteCounts = new uint256[](candidates.length); // Initialize vote counts array
        for (uint256 i = 0; i < candidates.length; i++) {
            candidateNames[i] = candidates[i].name; // Copy candidate names
            voteCounts[i] = candidates[i].voteCount; // Copy vote counts
        }
    }

    /// @notice Resets the election data after the election ends and the waiting period.
    /// @dev Restricted to the owner. Clears candidates and election state. Emits ElectionReset event.
    function resetElection() external onlyOwner {
        if (block.timestamp < electionEndTime + WEEK_DURATION) revert ResetNotAllowedYet(); // Ensure waiting period has passed

        delete candidates; // Clear candidate list
        electionOngoing = false; // Mark election as inactive
        emit ElectionReset();
    }

    /// @notice Retrieves the candidate with the highest vote count.
    /// @dev Returns the first candidate in case of a tie. Reverts if no candidates exist.
    /// @return name The name of the leading candidate.
    /// @return voteCount The number of votes for the leading candidate.
    function getLeadingCandidate() external view returns (string memory name, uint256 voteCount) {
        if (candidates.length == 0) revert NoCandidatesAvailable(); // Ensure candidates exist
        uint256 leadingIndex = 0; // Default to first candidate
        for (uint256 i = 1; i < candidates.length; i++) {
            if (candidates[i].voteCount > candidates[leadingIndex].voteCount) {
                leadingIndex = i; // Update leader if higher vote count found
            }
        }
        name = candidates[leadingIndex].name; // Return leading candidate's name
        voteCount = candidates[leadingIndex].voteCount; // Return leading candidate's vote count
    }
}
