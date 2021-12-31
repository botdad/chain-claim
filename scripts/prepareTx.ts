import { Contract, Wallet } from 'ethers'
import { splitSignature } from 'ethers/lib/utils'
import ExampleImplementationJson from '../out/ChainClaim.t.sol/ExampleImplementation.json'
import { ExampleImplementation } from './types'

const DEPLOYED_CLAIM_CONTRACT_ADDRESS =
  '0xb07dAd0000000000000000000000000000000001'

const main = async () => {
  const claimCode = {
    privateKey:
      '0x0a5589471b52f44060df73baf742061ea6dbd62575eb173c63108145bd42a2c5',
    v: 28,
    r: '0xa12aeea4f5ab2b8c0178a03dee44de8afdf20e29d3372c37596ad1f8b6055b4a',
    s: '0x46f49da040c486ebc0cd78b35487abbb482405765ab1d6fbd3bf535351114cae',
  }

  const userWallet = Wallet.createRandom()
  const oneTimeUseWallet = new Wallet(claimCode.privateKey)

  const domain = {
    name: 'some name',
    version: '1',
    chainId: 1,
    verifyingContract: DEPLOYED_CLAIM_CONTRACT_ADDRESS,
  }

  const types = {
    Claim: [{ name: 'chainedAddress', type: 'address' }],
  }

  const value = {
    chainedAddress: userWallet.address,
  }

  const signature = await userWallet._signTypedData(domain, types, value)
  const { v, r, s } = splitSignature(signature)

  const example = new Contract(
    DEPLOYED_CLAIM_CONTRACT_ADDRESS,
    ExampleImplementationJson.abi
  ) as ExampleImplementation

  const tx = await example
    .connect(userWallet)
    .populateTransaction.takeBalance(
      oneTimeUseWallet.address,
      [claimCode.v, v],
      [claimCode.r, r],
      [claimCode.s, s]
    )

  console.log(tx)
}

main()
