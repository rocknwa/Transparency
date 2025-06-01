# Transparency: A Secure Blockchain-Based Voting System

A secure, transparent, and decentralized election voting system built on Ethereum using Solidity. This project leverages blockchain technology to ensure tamper-proof, verifiable, and fair elections, addressing critical issues of election malpractice.

---

## Table of Contents

- [Transparency: A Secure Blockchain-Based Voting System](#transparency-a-secure-blockchain-based-voting-system)
  - [Table of Contents](#table-of-contents)
  - [Project Overview](#project-overview)
  - [Problem Statement](#problem-statement)
  - [How This Project Addresses Election Malpractice](#how-this-project-addresses-election-malpractice)
    - [Decentralized and Immutable Ledger](#decentralized-and-immutable-ledger)
    - [Voter Verification](#voter-verification)
    - [Transparent Process](#transparent-process)
    - [Access Control](#access-control)
    - [Election Reset Mechanism](#election-reset-mechanism)
    - [Auditable Code](#auditable-code)
  - [Features](#features)
  - [Technical Details](#technical-details)
    - [Key Components](#key-components)
  - [Smart Contract Architecture](#smart-contract-architecture)
    - [State Management](#state-management)
    - [Access Control](#access-control-1)
    - [Key Functions](#key-functions)
    - [Events](#events)
  - [Setup and Deployment](#setup-and-deployment)
    - [Prerequisites](#prerequisites)
    - [Installation](#installation)
    - [Deployment](#deployment)
    - [Interacting with the Contract](#interacting-with-the-contract)
  - [Testing](#testing)
  - [Future Enhancements](#future-enhancements)
  - [Contributing](#contributing)
  - [License](#license)
  - [Contact](#contact)

---

## Project Overview

**Transparency** is a decentralized application (dApp) designed to facilitate secure and transparent elections on the Ethereum blockchain. By leveraging the immutability and transparency of blockchain technology, this project ensures that votes are recorded accurately, verified securely, and remain tamper-proof. The smart contract is written in Solidity and follows industry best practices, including the use of OpenZeppelin for access control and Forge for rigorous testing.

This project is ideal for government bodies, organizations, or institutions looking to conduct fair and auditable elections. It is designed with modularity, security, and scalability in mind, making it a robust solution for real-world voting systems.

---

## Problem Statement

Election malpractice, such as vote tampering, voter suppression, and lack of transparency, undermines trust in democratic processes. Common issues include:

- **Vote Manipulation:** Unauthorized changes to vote counts or falsification of results.
- **Voter Fraud:** Multiple voting by individuals or impersonation of voters.
- **Lack of Transparency:** Opaque processes that prevent stakeholders from verifying election integrity.
- **Centralized Control:** Reliance on centralized systems prone to hacks or insider manipulation.
- **Inaccessible Audit Trails:** Difficulty in auditing election results to ensure fairness.

These challenges erode public confidence and can destabilize governance structures. A solution is needed to ensure secure, transparent, and verifiable elections.

---

## How This Project Addresses Election Malpractice

The `ElectionVoting` smart contract mitigates election malpractice through the following mechanisms:

### Decentralized and Immutable Ledger

- Votes are recorded on the Ethereum blockchain, ensuring they cannot be altered or deleted once cast.
- The decentralized nature eliminates reliance on a single point of failure, reducing the risk of tampering.

### Voter Verification

- A robust voter ID verification system ensures only authorized individuals can vote.
- Each voter ID is used only once, preventing duplicate voting or impersonation.

### Transparent Process

- All actions (e.g., adding candidates, casting votes, verifying voters) emit events logged on the blockchain, creating a public audit trail.
- Anyone can view candidate lists, vote counts, and election status in real-time.

### Access Control

- The contract uses OpenZeppelin's `Ownable` to restrict sensitive operations (e.g., starting elections, adding candidates) to the contract owner and authorized government officials.
- This ensures only trusted entities manage critical election processes.

### Election Reset Mechanism

- Post-election data is reset only after a mandatory waiting period (2 weeks), preventing premature resets and ensuring results are finalized transparently.
- Resetting clears candidate and voter data, preparing the system for future elections without compromising past records.

### Auditable Code

- Comprehensive unit tests using Forge ensure the contract behaves as expected under various scenarios, including edge cases and malicious inputs.
- The codebase follows Solidity best practices, reducing vulnerabilities and enhancing reliability.

By addressing these issues, ElectionVoting promotes trust, fairness, and accountability in the electoral process.

---

## Features

- **Voter Verification:** Securely verifies voters using unique national IDs to prevent fraud.
- **Candidate Management:** Allows the contract owner to add candidates before an election.
- **Vote Casting:** Verified voters can cast one vote per election, with votes recorded immutably.
- **Election Lifecycle Management:** Start, end, and reset elections with strict access controls.
- **Transparency:** Real-time access to candidate lists, vote counts, and election status.
- **Event Logging:** Emits events for all critical actions, enabling auditability.
- **Secure Access Control:** Leverages OpenZeppelin's Ownable for restricted administrative functions.
- **Modular Design:** Easily extensible for additional features or integrations.

---

## Technical Details

- **Blockchain:** Ethereum
- **Smart Contract Language:** Solidity ^0.8.24
- **Dependencies:**
  - OpenZeppelin Contracts (Ownable for access control)
  - Foundry (Forge) for testing and deployment scripts
- **License:** MIT

### Key Components

- `ElectionVoting.sol`: Core smart contract for managing the election process.
- `ElectionScript.sol`: Deployment script for the contract.
- `ElectionVotingTest.sol`: Comprehensive test suite to validate contract functionality.

---

## Smart Contract Architecture

The `ElectionVoting` contract is designed with modularity and security in mind:

### State Management

- Tracks election status (`electionOngoing`, `electionEndTime`)
- Maintains voter verification (`allowedVoterIDs`, `usedIDs`, `verifiedAddresses`)
- Stores candidate data (`Candidate` struct with name and vote count)

### Access Control

- `onlyOwner` modifier restricts critical functions (e.g., starting elections, adding candidates) to the contract owner.
- `onlyOfficial` modifier allows government officials to manage voter IDs.
- `electionActive` modifier ensures votes can only be cast during an active election.

### Key Functions

- `addGovtOfficial` / `removeGovtOfficial`: Manage government officials.
- `addAllowedVoterID`: Add verified voter IDs.
- `verifyVoter`: Verify a voter using their ID.
- `startElection`: Start an election with a specified duration.
- `addCandidates`: Add candidates before an election.
- `vote`: Cast a vote for a candidate.
- `getVotes`: Retrieve current vote counts.
- `getLeadingCandidate`: Identify the candidate with the most votes.
- `resetElection`: Reset election data after a cooldown period.

### Events

- Emitted for all significant actions (e.g., `Voted`, `ElectionStarted`, `VoterVerified`) to ensure transparency.

---

## Setup and Deployment

### Prerequisites

- [Foundry](https://getfoundry.sh/) for compiling, testing, and deploying
- MetaMask or another Ethereum wallet for deployment
- Access to an Ethereum testnet (e.g., Sepolia) or mainnet

### Installation

Clone the repository:

```bash
git clone https://github.com/rocknwa/Transparency.git
cd Transparency
```

Install dependencies:

```bash
forge install
```

Set up environment variables:

1. Create a `.env` file in the root directory.
2. Add your private key:
   ```bash
   PRIVATE_KEY=your_private_key_here
   ```

Compile the contracts:

```bash
forge build
```

### Deployment

Deploy the contract using the provided script:

```bash
forge script script/ElectionScript.sol --rpc-url <your-rpc-url> --broadcast
```

Replace `<your-rpc-url>` with the URL of your Ethereum node (e.g., from Alchemy).

The script deploys the ElectionVoting contract and logs the deployed address.

### Interacting with the Contract

Call functions like `startElection`, `addCandidates`, `verifyVoter`, and `vote` to manage the election process.

---

## Testing

The project includes a comprehensive test suite (`ElectionVotingTest.sol`) built with Forge. Tests cover:

- Government official management (add/remove officials)
- Voter verification (valid/invalid IDs, duplicate IDs)
- Election lifecycle (start, vote, reset)
- Candidate management (add candidates, invalid cases)
- Voting (successful votes, non-verified voters, double voting, invalid candidates)
- Vote counting and leading candidate retrieval

Run tests using:

```bash
forge test -vvv
```

For coverage:
```bash
forge coverage
```

All tests pass, ensuring the contract's reliability and security.

---

## Future Enhancements

- **Zero-Knowledge Proofs:** Implement ZKPs for voter privacy while maintaining verifiability.
- **Frontend Interface:** Develop a user-friendly dApp interface for voters and officials.
- **Gas Optimization:** Further optimize gas costs for large-scale elections.

---

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository.
2. Create a new branch:
   ```bash
   git checkout -b feature/your-feature
   ```
3. Make your changes and commit:
   ```bash
   git commit -m "Add your feature"
   ```
4. Push to the branch:
   ```bash
   git push origin feature/your-feature
   ```
5. Open a pull request.

Please ensure your code follows Solidity best practices and includes tests.

---

## License

This project is licensed under the MIT License ([LICENSE](LICENSE)).

---

## Contact

For inquiries, collaboration, or feedback:

- Email: [anitherock44@gmail.com](anitherock44@gmail.com)