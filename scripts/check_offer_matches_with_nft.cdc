import Offers from "../contracts/Offers.cdc"
import NonFungibleToken from "../contracts/utility/NonFungibleToken.cdc"
import MetadataViews from "../contracts/utility/MetadataViews.cdc"
import ExampleNFT from "../contracts/utility/ExampleNFT.cdc"

pub fun main(offerId: UInt64, offerCreator: Address, nftId: UInt64, nftAccountOwner: Address): Bool {
    let nftCollectionRef = getAccount(nftAccountOwner)
        .getCapability<&{ExampleNFT.ExampleNFTCollectionPublic}>(ExampleNFT.CollectionPublicPath)
        .borrow() 
        ?? panic("Unable to borrow given NFT account owner collection reference")
    let itemRef = nftCollectionRef.borrowExampleNFT(id: nftId) ?? panic("Unable to borrow given nftId")
    let offerPublicCap = getAccount(offerCreator)
        .getCapability<&{Offers.OpenOffersPublic}>(Offers.OpenOffersPublicPath)
        .borrow() 
        ?? panic("Unable to borrow offer creator's public capability")
    return offerPublicCap.borrowOffer(offerId: offerId)!.isGivenItemMatchesOffer(item: itemRef)
}