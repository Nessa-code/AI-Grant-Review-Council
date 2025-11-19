# AI Grant Review Council Platform

A blockchain-based grant review system combining AI assessment with human council review for transparent and efficient allocation of educational grants.

## Overview

This smart contract manages the entire grant lifecycle from proposal submission through AI-powered initial screening, council member reviews, and final award disbursement. All decisions are permanently recorded on the Stacks blockchain for complete transparency.

## Features

- **Proposal Submission**: Applicants submit grant proposals with funding requests
- **AI Assessment**: Initial AI-powered scoring and evaluation
- **Council Review**: Human reviewers provide independent scoring
- **Grant Pool Management**: Track available funding and allocations
- **Award System**: Transparent grant distribution with on-chain records
- **Member Management**: Control council membership and review participation

## Contract Functions

### Public Functions

- `add-council-member`: Add new reviewer to council (owner only)
- `submit-proposal`: Submit grant application
- `set-ai-score`: Record AI assessment score (owner only)
- `submit-review`: Council members submit review scores
- `update-proposal-status`: Change proposal status (owner only)
- `award-grant`: Allocate grant funding (owner only)
- `add-to-grant-pool`: Increase available grant funding (owner only)

### Read-Only Functions

- `get-proposal`: Retrieve proposal details
- `get-review`: View specific review
- `has-reviewe