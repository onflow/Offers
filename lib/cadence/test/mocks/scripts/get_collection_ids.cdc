import NonFungibleToken from "../../contracts/utility/NonFungibleToken.cdc"
import ExampleNFT from "../../contracts/utility/ExampleNFT.cdc"

/// Script to get NFT IDs in an account's collection
///
pub fun main(address: Address, collectionPublicPath: PublicPath, index: Int64): UInt64 {
    let account = getAccount(address)

    let collectionRef = account
        .getCapability(collectionPublicPath)
        .borrow<&{NonFungibleToken.CollectionPublic}>()
        ?? panic("Could not borrow capability from public collection at specified path")

    return (collectionRef.getIDs())[index]
}