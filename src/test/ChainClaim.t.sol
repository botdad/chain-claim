// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "ds-test/test.sol";
import "./Vm.sol";
import "../ChainClaim.sol";

contract ExampleImplementation is ChainClaim {
  // Deployer will be set as issuer of claim codes
  constructor(address issuerAddr, string memory name)
    payable
    ChainClaim(issuerAddr, name)
  {}

  function _isValidIssuerSig(
    address issuedAddress,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external view returns (bool) {
    return isValidIssuerSig(issuedAddress, v, r, s);
  }

  function _isValidClaimantSig(
    address issuedAddress,
    address destinationAddress,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external view returns (bool) {
    return isValidClaimantSig(issuedAddress, destinationAddress, v, r, s);
  }

  function _genDataHash(address chainedAddress)
    external
    view
    returns (bytes32)
  {
    return genDataHash(chainedAddress);
  }

  function takeBalance(
    address issuedAddress,
    uint8[2] memory v,
    bytes32[2] memory r,
    bytes32[2] memory s
  ) external {
    bool validClaim = claim(issuedAddress, msg.sender, v, r, s);

    require(validClaim, "Invalid claim");

    payable(msg.sender).transfer(address(this).balance);
  }
}

contract ChainClaimTestSetup {
  Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
  string name = "some name";
  // predetermined address for pregenerated test claim code signing
  address exAddress = 0xb07dAd0000000000000000000000000000000001;
  ExampleImplementation target = ExampleImplementation(exAddress);

  address issuerAddress = 0x0f6A79A579658E401E0B81c6dde1F2cd51d97176;
  uint256 issuerPkey =
    0xad54bdeade5537fb0a553190159783e45d02d316a992db05cbed606d3ca36b39;

  address claimCodeAddress = 0xB2DDDD291289EfF4715F6e84CdB3D845a93037A6;
  uint256 claimCodePkey =
    0x55b7b79aa0a71a634d00343ecb270adc0105d11566c7fcafa9381272d8d26554;

  uint8 claimCodeV;
  bytes32 claimCodeR;
  bytes32 claimCodeS;

  function setUp() public {
    ExampleImplementation deployedEx = new ExampleImplementation(
      issuerAddress,
      name
    );
    vm.etch(exAddress, address(deployedEx).code);

    (claimCodeV, claimCodeR, claimCodeS) = vm.sign(
      issuerPkey,
      target._genDataHash(claimCodeAddress)
    );
  }
}

contract ChainClaimTest is ChainClaimTestSetup, DSTest {
  receive() external payable {}

  function testIsValidIssuerSig() public {
    bool valid = target._isValidIssuerSig(
      claimCodeAddress,
      claimCodeV,
      claimCodeR,
      claimCodeS
    );

    assertTrue(valid);
  }

  function testIsInvalidIssuerSig() public {
    bool valid;
    valid = target._isValidIssuerSig(
      claimCodeAddress,
      claimCodeV,
      claimCodeR,
      bytes32(uint256(claimCodeS) + 1)
    );
    assertTrue(!valid);

    valid = target._isValidIssuerSig(
      claimCodeAddress,
      claimCodeV,
      bytes32(uint256(claimCodeR) + 1),
      claimCodeS
    );
    assertTrue(!valid);

    valid = target._isValidIssuerSig(
      claimCodeAddress,
      claimCodeV + 1,
      claimCodeR,
      claimCodeS
    );
    assertTrue(!valid);

    valid = target._isValidIssuerSig(
      address(0),
      claimCodeV,
      claimCodeR,
      claimCodeS
    );
    assertTrue(!valid);
  }

  function testIsValidClaimantSig() public {
    address someAddress = 0xB07DAd0000000000000000000000000000000002;
    bytes32 hash = target._genDataHash(someAddress);

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(claimCodePkey, hash);
    bool valid = target._isValidClaimantSig(
      claimCodeAddress,
      someAddress,
      v,
      r,
      s
    );

    assertTrue(valid);
  }

  function testIsInvalidClaimantSig() public {
    address someAddress = 0xB07DAd0000000000000000000000000000000002;
    bytes32 hash = target._genDataHash(someAddress);

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(claimCodePkey, hash);

    bool valid;
    valid = target._isValidClaimantSig(
      claimCodeAddress,
      someAddress,
      v,
      r,
      bytes32(uint256(s) + 1)
    );
    assertTrue(!valid);

    vm.expectRevert("ECDSA: invalid signature");
    valid = target._isValidClaimantSig(
      claimCodeAddress,
      someAddress,
      v,
      bytes32(uint256(r) + 2),
      s
    );
    assertTrue(!valid);

    vm.expectRevert("ECDSA: invalid signature 'v' value");
    valid = target._isValidClaimantSig(
      claimCodeAddress,
      someAddress,
      v - 1,
      r,
      s
    );
    assertTrue(!valid);

    valid = target._isValidClaimantSig(address(0), someAddress, v, r, s);
    assertTrue(!valid);

    valid = target._isValidClaimantSig(claimCodeAddress, address(0), v, r, s);
    assertTrue(!valid);
  }

  function testClaim() public {
    vm.deal(address(target), 1 ether);
    vm.deal(address(this), 0);

    bytes32 hash = target._genDataHash(address(this));
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(claimCodePkey, hash);

    vm.expectRevert(
      abi.encodePacked(bytes4(keccak256("ErrorInvalidIssuerSignature()")))
    );
    target.takeBalance(
      address(0),
      [claimCodeV, v],
      [claimCodeR, r],
      [claimCodeS, s]
    );

    vm.expectRevert(
      abi.encodePacked(bytes4(keccak256("ErrorInvalidIssuerSignature()")))
    );
    target.takeBalance(
      claimCodeAddress,
      [claimCodeV, v],
      [claimCodeR, r],
      [bytes32(uint256(claimCodeS) + 1), s]
    );

    vm.expectRevert(
      abi.encodePacked(bytes4(keccak256("ErrorInvalidClaimantSignature()")))
    );
    target.takeBalance(
      claimCodeAddress,
      [claimCodeV, v],
      [claimCodeR, r],
      [claimCodeS, bytes32(uint256(s) + 1)]
    );

    target.takeBalance(
      claimCodeAddress,
      [claimCodeV, v],
      [claimCodeR, r],
      [claimCodeS, s]
    );

    assertEq(address(target).balance, 0, "target balance not 0");
    assertEq(address(this).balance, 1 ether, "this balance not 1 ether");

    vm.expectRevert(abi.encodePacked(bytes4(keccak256("ErrorUsedClaim()"))));
    target.takeBalance(
      claimCodeAddress,
      [claimCodeV, v],
      [claimCodeR, r],
      [claimCodeS, s]
    );
  }
}
