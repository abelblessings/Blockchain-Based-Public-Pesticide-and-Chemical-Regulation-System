# Blockchain-Based Public Pesticide and Chemical Regulation System

## Overview

This system provides a decentralized platform for managing pesticide and chemical regulation through five interconnected smart contracts on the Stacks blockchain. The system ensures transparency, accountability, and efficient coordination of chemical safety measures.

## System Architecture

### Core Contracts

1. **Pesticide Permits Contract** (`pesticide-permits.clar`)
    - Issues permits for commercial pesticide use
    - Tracks application status and compliance
    - Manages permit renewals and revocations

2. **Chemical Storage Inspection Contract** (`chemical-storage-inspection.clar`)
    - Manages inspections of hazardous chemical storage facilities
    - Tracks compliance scores and violation records
    - Schedules routine and emergency inspections

3. **Pesticide Residue Testing Contract** (`pesticide-residue-testing.clar`)
    - Records pesticide contamination tests on food and water
    - Maintains testing results and safety thresholds
    - Alerts for contamination violations

4. **Chemical Spill Response Contract** (`chemical-spill-response.clar`)
    - Coordinates emergency response to chemical accidents
    - Manages cleanup operations and resource allocation
    - Tracks incident reports and response times

5. **Integrated Pest Management Contract** (`integrated-pest-management.clar`)
    - Promotes environmentally friendly pest control alternatives
    - Tracks adoption of sustainable practices
    - Provides incentives for eco-friendly methods

## Key Features

- **Transparency**: All regulatory actions are recorded on-chain
- **Accountability**: Immutable audit trail for all operations
- **Efficiency**: Automated compliance checking and notifications
- **Interoperability**: Contracts work together to provide comprehensive oversight
- **Public Access**: Citizens can verify regulatory compliance

## Data Models

### Permit Structure
- Permit ID, applicant, pesticide type, application area
- Issue date, expiration date, status
- Compliance history and conditions

### Inspection Records
- Facility ID, inspector, inspection date
- Compliance score, violations found
- Corrective actions required

### Test Results
- Sample ID, location, test date
- Pesticide levels detected, safety thresholds
- Pass/fail status and recommendations

### Spill Incidents
- Incident ID, location, chemical type
- Severity level, response team assigned
- Cleanup status and completion date

### IPM Programs
- Program ID, participant, implementation date
- Methods adopted, effectiveness metrics
- Incentives earned and environmental impact

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Stacks wallet for contract deployment

### Installation
\`\`\`bash
git clone <repository-url>
cd pesticide-regulation-system
npm install
clarinet check
\`\`\`

### Testing
\`\`\`bash
npm test
\`\`\`

### Deployment
\`\`\`bash
clarinet deploy --testnet
\`\`\`

## Usage Examples

### Issue a Pesticide Permit
\`\`\`clarity
(contract-call? .pesticide-permits issue-permit
"Acme Pest Control"
"Glyphosate"
u1000
u365)
\`\`\`

### Schedule Facility Inspection
\`\`\`clarity
(contract-call? .chemical-storage-inspection schedule-inspection
u1
tx-sender
u1640995200)
\`\`\`

### Record Test Results
\`\`\`clarity
(contract-call? .pesticide-residue-testing record-test-result
"SAMPLE-001"
"Organic Farm A"
u50
u100)
\`\`\`

## Governance

The system includes role-based access controls:
- **Regulators**: Can issue permits and schedule inspections
- **Inspectors**: Can conduct inspections and record results
- **Labs**: Can submit test results
- **Emergency Responders**: Can coordinate spill response
- **Public**: Can view all records and compliance status

## Compliance and Reporting

All contracts maintain comprehensive logs for:
- Regulatory compliance tracking
- Environmental impact assessment
- Public health monitoring
- Emergency response effectiveness

## Contributing

Please read our contributing guidelines and submit pull requests for any improvements.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
