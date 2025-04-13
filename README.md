# Election Voting Smart Contract

**Author:** scorpion@DESKTOP-I7EFSIL  
**License:** [MIT](LICENSE)

---

## Table of Contents

- [Election Voting Smart Contract](#election-voting-smart-contract)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Features](#features)
  - [Architecture and Design](#architecture-and-design)
    - [Components](#components)
    - [Key Design Decisions](#key-design-decisions)
  - [Installation](#installation)
    - [Prerequisites](#prerequisites)
    - [Steps](#steps)
  - [Usage](#usage)
    - [Running Tests](#running-tests)
    - [Example Commands](#example-commands)
  - [Project Structure](#project-structure)
  - [Deployment](#deployment)
  - [Contributing](#contributing)
  - [Acknowledgements](#acknowledgements)

---

## Overview

The **Election Voting Smart Contract** is a secure and transparent decentralized application (dApp) designed for election management. The contract is built using Solidity (version ^0.8.24) and follows best practices in decentralized governance. It provides functionality for:
- Managing government official roles.
- Verifying voters using approved national IDs.
- Adding and managing candidate nominations.
- Casting votes during an active election.
- Resetting elections after completion.

The project leverages OpenZeppelin’s `Ownable` contract to enforce administrative controls, ensuring that only authorized addresses can perform sensitive operations.

---

## Features

- **Government Official Management**  
  The contract allows the owner to designate government officials. These officials can add allowed voter IDs, streamlining the voter verification process.

- **Voter Verification**  
  Users are verified using a pre-approved voter ID. Each ID can be used only once for verification, ensuring uniqueness and authenticity in the voting process.

- **Candidate Management**  
  Candidates are added before an election begins. The contract maintains a list of candidates along with their vote counts. It supports adding candidates only when no election is active, ensuring data integrity during voting.

- **Voting Process**  
  Only verified voters can cast their vote using a one-based candidate index. The contract checks for duplicate votes and invalid candidate selections.

- **Election Lifecycle**  
  The smart contract allows the owner to start a new election for a specific duration. It also supports election reset procedures after a cool-down period (defined by a week duration) to facilitate subsequent elections without legacy data.

- **Security and Auditing**  
  Following industry best practices, the contract implements strict access control, event logging, and proper state management. Test suites are provided to ensure robust functionality and prevent common pitfalls such as out-of-bound array errors.

---

## Architecture and Design

### Components

1. **ElectionVoting Contract**  
   Implements core functionalities such as candidate management, vote casting, voter verification, and reset mechanism.

2. **Administration Functions**  
   Functions guarded by access modifiers (e.g., `onlyOwner`, `onlyOfficial`) ensure that only the right entities can add officials, start elections, or reset election data.

3. **Testing Suite**  
   Comprehensive tests (using Forge and Foundry) cover all core functionalities:
   - **GovtOfficial Management Tests**
   - **Voter Verification Tests**
   - **Election Start/Reset Tests**
   - **Candidate Addition & Voting Tests**
   - **Edge Case Handling and Reverts**

### Key Design Decisions

- **Access Control:**  
  The use of OpenZeppelin's `Ownable` contract provides a proven, secure base for restricted administrative functions.
  
- **Event Logging:**  
  Key actions emit events (e.g., `ElectionStarted`, `Voted`, `ElectionReset`), aiding on-chain transparency and off-chain monitoring.

- **State Management:**  
  Candidate details and voter statuses are stored using arrays and mappings, ensuring efficient state retrieval and updating.

---

## Installation

### Prerequisites

- **Node.js & npm/yarn**: For JavaScript tooling and potential frontend integrations.
- **Foundry**:  
  Follow the [Foundry Installation Guide](https://github.com/foundry-rs/foundry) to install Forge, Cast, and Anvil.
- **Solidity Compiler (Solc)**: Version 0.8.26 is used in this project.
- **OpenZeppelin Contracts**: Integrated via the local `lib` folder or package manager.

### Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-org/election-voting.git
   cd election-voting
   ```

2. **Install Foundry (if not already installed):**
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

3. **Install Dependencies:**
   If you are using a package manager, install OpenZeppelin Contracts:
   ```bash
   npm install @openzeppelin/contracts
   # or
   yarn add @openzeppelin/contracts
   ```

4. **Build the Project:**
   ```bash
   forge build
   ```

---

## Usage

### Running Tests

To run the entire test suite and get coverage metrics:
  
```bash
forge test
```

For test coverage (note the warning about optimizer settings for accurate coverage reports):

```bash
forge coverage
```

The output will show details on gas usage and pass/fail status for each test.

### Example Commands

- **Compile Contracts:**
  ```bash
  forge build
  ```

- **Run Specific Test Suite:**
  ```bash
  forge test --match-path test/ElectionVoting.t.sol
  ```

- **Deploy Locally (Anvil):**
  Start an Anvil node:
  ```bash
  anvil
  ```
  Deploy contracts with your preferred deployment script or by using Cast.

---

## Project Structure

```plaintext
├── contracts
│   └── ElectionVoting.sol        # Core smart contract for election voting
├── lib
│   └── openzeppelin-contracts    # OpenZeppelin library (if not installed via npm/yarn)
├── script
│   └── ElectionVoting.s.sol      # Deployment script(s)
├── test
│   └── ElectionVoting.t.sol      # Comprehensive test suite using Forge
├── README.md                     # Project documentation
├── foundry.toml                  # Foundry configuration file
└── package.json                  # Project package configuration (if using npm/yarn)
```

---

## Deployment

For production deployments on testnets or mainnet, ensure that you:

- **Conduct a thorough audit** of the contract code.
- **Configure deployment parameters** (e.g., gas limits, optimizations) appropriately.
- **Leverage deployment scripts** (found in the `script` directory) for reproducibility.

Deployment can be performed using Foundry’s `forge script` command. For instance:

```bash
forge script script/ElectionVoting.s.sol --broadcast --verify
```

Ensure you have configured your private keys and provider settings appropriately in your environment.

---

## Contributing

We welcome contributions from the community! Please follow these guidelines:

1. Fork the repository and create your feature branch.
2. Write tests for your changes.
3. Ensure that your code adheres to the Solidity style guide.
4. Submit a pull request describing your changes.

For detailed contributing guidelines, see [CONTRIBUTING.md](CONTRIBUTING.md).


---

## Acknowledgements

- **OpenZeppelin:** For providing robust, secure smart contract libraries.
- **Foundry & Cast:** For an excellent development environment for Solidity.
- **Community and Reviewers:** For their feedback and contributions to improve this project.

 