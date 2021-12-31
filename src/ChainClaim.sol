// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

abstract contract ChainClaim is EIP712 {
  error ErrorUsedClaim();
  error ErrorInvalidIssuerSignature();
  error ErrorInvalidClaimantSignature();

  bytes32 private immutable _CHAIN_CLAIM_TYPEHASH =
    keccak256("Claim(address chainedAddress)");

  address public immutable ISSUER;

  mapping(address => bool) public usedClaims;

  /// @notice On chain generation for a valid EIP-712 hash
  /// @param _issuer the address that must match the signing
  /// private key for all claim codes
  /// @param name EIP712 name
  constructor(address _issuer, string memory name) EIP712(name, "1") {
    ISSUER = _issuer;
  }

  /// @notice On chain generation for a valid EIP-712 hash
  /// @param chainedAddress the address that has been signed
  /// @return The typed data hash
  function genDataHash(address chainedAddress) internal view returns (bytes32) {
    bytes32 structHash = keccak256(
      abi.encode(_CHAIN_CLAIM_TYPEHASH, chainedAddress)
    );

    return _hashTypedDataV4(structHash);
  }

  /// @notice First of two signature validations, signer must match ISSUER
  /// @param issuedAddress the address that has been signed,
  /// this address must match the claim code private key
  /// @param v split signature v
  /// @param r split signature r
  /// @param s split signature s
  /// @return True if signature is valid and signer matches issuer
  function isValidIssuerSig(
    address issuedAddress,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal view returns (bool) {
    bytes32 hash = genDataHash(issuedAddress);

    address signer = ECDSA.recover(hash, v, r, s);

    return signer == ISSUER;
  }

  /// @notice Second of two signature validations, signer must match
  /// issued address from the first signature validation
  /// @param issuedAddress address that much match the signer address
  /// @param destinationAddress the address that has been signed,
  /// this is the final address for whatever can be claimed, can be msg.sender
  /// @param v split signature v
  /// @param r split signature r
  /// @param s split signature s
  /// @return True if signature is valid and signer matches issuedAddress
  function isValidClaimantSig(
    address issuedAddress,
    address destinationAddress,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal view returns (bool) {
    bytes32 hash = genDataHash(destinationAddress);

    address signer = ECDSA.recover(hash, v, r, s);

    return signer == issuedAddress;
  }

  /// @notice Validates the chain of two signatures the first is an adddress
  /// signed by the issuer. The second is a final address signed by a one
  /// time use private key before sending the transaction. The final address
  /// should be the destination address for whatever is being claimed
  /// @param issuedAddress address that has been signed by issuer
  /// @param destinationAddress address that has been signed by claimant
  /// this is the final address for whatever can be claimed, can be msg.sender
  /// @param v array of split signature v
  /// @param r array of split signature r
  /// @param s array of split signature s
  /// @return True if signature chain is valid
  function claim(
    address issuedAddress,
    address destinationAddress,
    uint8[2] memory v,
    bytes32[2] memory r,
    bytes32[2] memory s
  ) internal returns (bool) {
    if (usedClaims[issuedAddress]) {
      revert ErrorUsedClaim();
    }

    if (!isValidIssuerSig(issuedAddress, v[0], r[0], s[0]))
      revert ErrorInvalidIssuerSignature();

    if (
      !isValidClaimantSig(issuedAddress, destinationAddress, v[1], r[1], s[1])
    ) revert ErrorInvalidClaimantSignature();

    usedClaims[issuedAddress] = true;

    return true;
  }
}
