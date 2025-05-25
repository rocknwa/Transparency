// The contract is designed to be secure and efficient, following best practices in Solidity development.
// It includes proper access control, event logging, and state management to ensure a smooth election process.
// The use of OpenZeppelin's Ownable contract ensures that only the owner can perform certain administrative actions.
// The contract is modular, allowing for easy updates and maintenance.
// The election process is transparent, with clear functions for adding candidates, verifying voters, and casting votes.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title ElectionVoting - A secure election voting system following industry standards.
/// @notice This contract allows government officials to add allowed voter IDs, verifies voters, manages candidate nominations, voting, and resets election data.
contract ElectionVoting is Ownable {
    // Constants
    uint256 public constant WEEK_DURATION = 2 weeks;
    //uint256 public constant WEEK_DURATION = 7 days;

    // Election state variables
    uint256 public electionEndTime;
    bool public electionOngoing;

    // Voter verification mappings
    mapping(uint256 => bool) private allowedVoterIDs; // Approved national IDs for verification
    mapping(uint256 => bool) private usedIDs; // Tracks if a voter ID has already been used
    mapping(address => bool) public verifiedAddresses; // Tracks verified voter addresses

    // Government official mappings
    mapping(address => bool) public govtOfficials;

    // Candidate structure
    struct Candidate {
        string name;
        uint256 voteCount;
    }

    Candidate[] public candidates;

    // Tracks if an address has already voted
    uint256 public electionId;
    mapping(address => uint256) public lastVotedElection;

    // --- Events ---
    event GovtOfficialAdded(address indexed official);
    event GovtOfficialRemoved(address indexed official);
    event VoterIdAdded(uint256 indexed voterId);
    event VoterVerified(address indexed voter, uint256 voterId);
    event ElectionStarted(uint256 indexed endTime);
    event CandidateAdded(string candidateName);
    event Voted(address indexed voter, uint256 candidateIndex);
    event ElectionReset();

    // --- Constructor ---
    constructor() {
        // The deployer is set as owner via Ownable, and also registered as a government official.
        govtOfficials[msg.sender] = true;
    }

    // --- Modifiers ---
    modifier onlyOfficial() {
        require(govtOfficials[msg.sender], "Only government officials can call this function");
        _;
    }

    modifier electionActive() {
        require(electionOngoing, "Election is not active");
        require(block.timestamp < electionEndTime, "Election has ended");
        _;
    }

    function isGovtOfficial(address _official) public view returns (bool) {
        return govtOfficials[_official];
    }

    function isVerifiedVoter(address _voter) public view returns (bool) {
        return verifiedAddresses[_voter];
    }

    // --- Administration Functions ---
    /// @notice Adds a government official who may manage allowed voter IDs.
    /// @param _official Address of the official.
    function addGovtOfficial(address _official) external onlyOwner {
        govtOfficials[_official] = true;
        emit GovtOfficialAdded(_official);
    }

    /// @notice Removes a government official.
    /// @param _official Address of the official.
    function removeGovtOfficial(address _official) external onlyOwner {
        govtOfficials[_official] = false;
        emit GovtOfficialRemoved(_official);
    }

    /// @notice Allows a government official to add a verified voter ID.
    /// @param _id The national voter ID to allow.
    function addAllowedVoterID(uint256 _id) external onlyOfficial {
        allowedVoterIDs[_id] = true;
        emit VoterIdAdded(_id);
    }

    /// @notice Verifies the caller as a voter if a valid voter ID is provided.
    /// @param _id The voter ID to verify.
    function verifyVoter(uint256 _id) external {
        require(!usedIDs[_id], "ID has already been used for verification");
        require(allowedVoterIDs[_id], "ID is not recognized");

        verifiedAddresses[msg.sender] = true;

        usedIDs[_id] = true;
        emit VoterVerified(msg.sender, _id);
    }

    /// @notice Starts an election for a specified duration.
    /// @param _durationInMinutes Duration of the election in minutes.
    function startElection(uint256 _durationInMinutes) external onlyOwner {
        require(!electionOngoing || block.timestamp >= electionEndTime, "Election is already active");
        uint256 duration = _durationInMinutes * 60;
        electionEndTime = block.timestamp + duration;
        electionOngoing = true;
        electionId += 1; // increment electionId to start a new voting session
        emit ElectionStarted(electionEndTime);
    }

    /// @notice Adds multiple candidates before an election begins.
    /// @param _candidateNames An array of candidate names.
    function addCandidates(string[] calldata _candidateNames) external onlyOwner {
        require(!electionOngoing, "Cannot add candidates during an active election");
        for (uint256 i = 0; i < _candidateNames.length; i++) {
            candidates.push(Candidate({name: _candidateNames[i], voteCount: 0}));
            emit CandidateAdded(_candidateNames[i]);
        }
    }

    /// @notice Retrieves the list of candidate names and their corresponding 1-based indexes.
    /// @return candidateNames An array of candidate names.
    /// @return indexes An array of candidate indexes (starting from 1).
    function getCandidates() external view returns (string[] memory candidateNames, uint256[] memory indexes) {
        candidateNames = new string[](candidates.length);
        indexes = new uint256[](candidates.length);
        for (uint256 i = 0; i < candidates.length; i++) {
            candidateNames[i] = candidates[i].name;
            indexes[i] = i + 1;
        }
    }

    /// @notice Casts a vote for the candidate specified by a 1-based index.
    /// @param _candidateNumber The 1-based index of the candidate.
    function vote(uint256 _candidateNumber) external electionActive {
        require(verifiedAddresses[msg.sender], "Voter not verified");
        require(lastVotedElection[msg.sender] < electionId, "You have already voted");
        lastVotedElection[msg.sender] = electionId;

        require(_candidateNumber > 0 && _candidateNumber <= candidates.length, "Invalid candidate number");

        uint256 candidateIndex = _candidateNumber - 1;
        candidates[candidateIndex].voteCount += 1;

        emit Voted(msg.sender, candidateIndex);
    }

    /// @notice Retrieves the candidate names along with their current vote counts.
    /// @return candidateNames An array of candidate names.
    /// @return voteCounts An array of corresponding vote counts.
    function getVotes() external view returns (string[] memory candidateNames, uint256[] memory voteCounts) {
        candidateNames = new string[](candidates.length);
        voteCounts = new uint256[](candidates.length);
        for (uint256 i = 0; i < candidates.length; i++) {
            candidateNames[i] = candidates[i].name;
            voteCounts[i] = candidates[i].voteCount;
        }
    }

    /// @notice Resets the election data (candidates and voter statuses) after the election and after the set week duration.
    /// @dev Resets the candidates array, the voting status of all verified voters, and marks the election as ended.
    function resetElection() external onlyOwner {
        require(block.timestamp >= electionEndTime + WEEK_DURATION, "Reset not allowed yet");

        delete candidates;

        electionOngoing = false;
        emit ElectionReset();
    }

    /// @notice Retrieves the leading candidate based on vote count.
    /// @return name The name of the leading candidate.
    /// @return voteCount The number of votes the leading candidate received.
    function getLeadingCandidate() external view returns (string memory name, uint256 voteCount) {
        require(candidates.length > 0, "No candidates available");
        uint256 leadingIndex = 0;
        for (uint256 i = 1; i < candidates.length; i++) {
            if (candidates[i].voteCount > candidates[leadingIndex].voteCount) {
                leadingIndex = i;
            }
        }
        name = candidates[leadingIndex].name;
        voteCount = candidates[leadingIndex].voteCount;
    }
}
