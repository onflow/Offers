import NonFungibleToken from "CoreContractsAccount"
import ExampleNFT from "CoreContractsAccount"

/// Script to get NFT IDs in an account's collection
///
pub fun main(address: Address, collectionPublicPath: PublicPath): Int64 {
    let account = getAccount(address)

    let collectionRef = account
        .getCapability(collectionPublicPath)
        .borrow<&{NonFungibleToken.CollectionPublic}>()
        ?? panic("Could not borrow capability from public collection at specified path")

    return Int64((collectionRef.getIDs()).length)
}