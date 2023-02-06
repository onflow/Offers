# Offers Contract

## The core folder is not for deployment

For simplicity, we copy the Flow core contract into the project folder here. This is to mitigate program
non-compilation since on-chain contracts may be updated at a future time. 

Developers need not deploy the contracts listed below. Contract standards must reference the correct contract addresses on-chain. Cadence contract imports behave intuitively like imports in other languages; the imported type definitions become available at the runtime scope.

* FungibleToken.cdc
* ExampleNFT.cdc
* ExampleToken.cdc
* MetadataViews.cdc
* FungibleTokenSwitchboard.cdc
* NonFungibleToken.cdc

Applications should reference the above contracts by their deployed addresses. Detailed information is provided
in [Flow Core Contracts and Standards](https://developers.flow.com/flow/core-contracts)