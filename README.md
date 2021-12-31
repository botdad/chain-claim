# Chain Claim

This repository contains a solidity lib and helper scripts for providing claim code generation and on chain verification of a claim.

Reasons to use this lib over merkle proofs:

- No reliance on a pre generated list
- Uses EIP-712 ECDSA signing from an issuer private key
- A nearly-infinite number of claim codes can be generated
- No interactivity needed during the delivery of a claim code (could be printed)
- Secondary signing step to provide front running protection

Each claim code is a one-time-use private key and issuer EIP-712 valid ECDSA signature. The issuer signs the address matching the one-time-use private key. To provide frontrunning protection the user will then use the one-time-use private key to sign (potentially transparently with some nice ux) a destination address that will receive whatever is to be claimed.

Issuer signs one-time address off chain -> one-time signs claimant address off chain -> claimant receives with on-chain signature verification

By verifying that the secondary signer matches the address that is signed by the issuer you provide a chain of trust, protect against frontrunning, and allow the transaction sender to be an arbitrary address, no need to fund the one-time-use address.

## Local build and test

Must have [foundry](https://github.com/gakonst/foundry) and node installed and functioning

Install deps:

```sh
yarn
```

Build:

```sh
yarn build
```

Test:

```sh
forge test
```

## Example scripts

### Generate a claim code

set [`ISSUER_PRIVATE_KEY`](./scripts/generateClaimCode.ts.ts#L4) and [`DEPLOYED_CLAIM_CONTRACT_ADDRESS`](./scripts/generateClaimCode.ts.ts#L5).

```sh
yarn generate-code
```

### Prepare example transaction for claim

set [`claimCode`](./scripts/prepareTx.ts.ts#L10).

```sh
yarn prepare-tx
```

## Licensing

Licensed under the MIT license, see [`LICENSE`](./LICENSE.txt).
