// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @dev Therock Ani
 */
contract ElectionVoting {
    address public owner; // Address of the contract owner
    uint256 public electionEndTime; // Timestamp marking the end of the election
    bool public electionOngoing; // Flag indicating if the election is ongoing

    uint256 constant weekDuration = 2 weeks; // Duration after which certain actions can be reset

    uint256[] private votersIDs; // Array storing verified voter IDs
    mapping(uint256 => bool) private usedIDs; // Tracks used IDs to prevent duplicate verifications
    mapping(address => bool) private verifiedAddresses; // Stores verified voters
    address[] private voters; // Array of voter addresses
    mapping(address => bool) private govtOfficials; // Tracks government officials with special permissions

    struct Candidate {
        string name; // Name of the candidate
        uint256 voteCount; // Total votes the candidate has received
    }

    Candidate[] public candidates; // Array storing candidates
    mapping(address => bool) private hasVoted; // Tracks if an address has already voted

    constructor() {
        owner = msg.sender; // Sets the contract deployer as the owner
        govtOfficials[owner] = true; // Adds the deployer as a government official
    }

    // Modifier to restrict function access to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    // Modifier to ensure an election is ongoing and within its time limit
    modifier electionIsOngoing() {
        require(electionOngoing, "Election is not ongoing");
        require(block.timestamp < electionEndTime, "Election time has ended");
        _;
    }

    // Modifier to restrict function access to government officials
    modifier onlyOfficials() {
        require(govtOfficials[msg.sender], "Only government officials can call this function");
        _;
    }

    // Adds a government official who has permissions to add voter IDs
    function addGovtOfficial(address _official) public onlyOwner {
        govtOfficials[_official] = true;
    }

    // Removes a government official's permissions
    function removeGovtOfficial(address _official) public onlyOwner {
        govtOfficials[_official] = false;
    }

    // Allows government officials to add verified voter IDs
    function addVIN(uint256 _id) public onlyOfficials {
        votersIDs.push(_id);
    }

    // Verifies a voter's ID, adds their address to the verified list, and prevents duplicate verification
    function verifyVoter(uint256 _id) public {
        require(!usedIDs[_id], "ID has already been used for verification");

        bool idExists = false;
        for (uint256 i = 0; i < votersIDs.length; i++) {
            if (votersIDs[i] == _id) {
                idExists = true;
                break;
            }
        }
        require(idExists, "ID does not exist in the allowed national IDs list");

        verifiedAddresses[msg.sender] = true;
        voters.push(msg.sender);
        usedIDs[_id] = true;
    }

    // Sets the election duration and marks the election as ongoing
    function setElectionTime(uint256 _duration) public onlyOwner {
        uint256 duration = _duration * 60; // Converts input to seconds
        require(!electionOngoing || block.timestamp >= electionEndTime, "Election time is still ongoing");
        electionEndTime = block.timestamp + duration;
        electionOngoing = true;
    }

    // Allows the owner to add candidates before an election begins
    function addCandidates(string[] memory _candidateNames) public onlyOwner {
        require(!electionOngoing, "Cannot add candidates while election is ongoing");
        for (uint256 i = 0; i < _candidateNames.length; i++) {
            candidates.push(Candidate(_candidateNames[i], 0));
        }
    }

    // Returns an array of candidate names and their respective indexes
    function getCandidates() public view returns (string[] memory, uint256[] memory) {
        string[] memory names = new string[](candidates.length);
        uint256[] memory indexes = new uint256[](candidates.length);

        for (uint256 i = 0; i < candidates.length; i++) {
            names[i] = candidates[i].name;
            indexes[i] = i + 1; // Display 1-based index
        }

        return (names, indexes);
    }

    // Allows a verified voter to cast their vote for a candidate
    function vote(uint256 _candidateNumber) public electionIsOngoing {
        require(verifiedAddresses[msg.sender], "You are not verified to vote");
        require(!hasVoted[msg.sender], "You have already voted");

        require(_candidateNumber > 0 && _candidateNumber <= candidates.length, "Invalid candidate number");

        uint256 candidateIndex = _candidateNumber - 1; // Convert to 0-based index
        candidates[candidateIndex].voteCount += 1;
        hasVoted[msg.sender] = true;
    }

    // Returns each candidate's name and their current vote count
    function getVotes() public view returns (string[] memory, uint256[] memory) {
        string[] memory names = new string[](candidates.length);
        uint256[] memory votes = new uint256[](candidates.length);

        for (uint256 i = 0; i < candidates.length; i++) {
            names[i] = candidates[i].name;
            votes[i] = candidates[i].voteCount;
        }

        return (names, votes);
    }

    // Allows the owner to reset the list of candidates after a set duration from election end
    function resetCandidates() public onlyOwner {
        require(block.timestamp >= electionEndTime + weekDuration, "Cannot reset candidates yet");
        delete candidates;
    }

    // Allows the owner to reset each candidate's vote count after a set duration from election end
    function resetVotes() public onlyOwner {
        require(block.timestamp >= electionEndTime + weekDuration, "Cannot reset votes yet");
        for (uint256 i = 0; i < candidates.length; i++) {
            candidates[i].voteCount = 0;
        }
    }

    // Allows the owner to reset voting status for each voter after a set duration from election end
    function resetHasVoted() public onlyOwner {
        require(block.timestamp >= electionEndTime + weekDuration, "Cannot reset voting status yet");
        for (uint256 i = 0; i < voters.length; i++) {
            hasVoted[voters[i]] = false;
        }
    }

    // Returns the name and vote count of the leading candidate
    function getLeadingCandidate() public view returns (string memory, uint256) {
        require(candidates.length > 0, "No candidates available");

        string memory leadingCandidateName;
        uint256 leadingVoteCount = 0;

        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > leadingVoteCount) {
                leadingVoteCount = candidates[i].voteCount;
                leadingCandidateName = candidates[i].name;
            }
        }

        return (leadingCandidateName, leadingVoteCount);
    }
}
