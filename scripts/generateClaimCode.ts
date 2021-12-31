import { Wallet } from 'ethers'
import { splitSignature } from 'ethers/lib/utils'

const ISSUER_PRIVATE_KEY =
  '0xad54bdeade5537fb0a553190159783e45d02d316a992db05cbed606d3ca36b39'
const DEPLOYED_CLAIM_CONTRACT_ADDRESS =
  '0xb07dAd0000000000000000000000000000000001'

const main = async () => {
  const issuerWallet = new Wallet(ISSUER_PRIVATE_KEY)

  const oneTimeUseWallet = Wallet.createRandom()

  console.log(issuerWallet.privateKey)
  console.log(issuerWallet.address)

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
    chainedAddress: oneTimeUseWallet.address,
  }

  const signature = await issuerWallet._signTypedData(domain, types, value)
  const { v, r, s } = splitSignature(signature)

  console.log({ privateKey: oneTimeUseWallet.privateKey, v, r, s })
}

main()
