import Offers from "../contracts/Offers.cdc"
import NonFungibleToken from "../contracts/core/NonFungibleToken.cdc"
import MetadataViews from "../contracts/core/MetadataViews.cdc"
import ExampleNFT from "../contracts/core/ExampleNFT.cdc"

/// This script tells whether the givein `nftId` matches the filter of the given `offerId`
///
/// # Params
/// @param offerId ID of the offer corresponds to which `nftId` acceptance get checked
/// @param offerCreator Address of the account which holds the offer resource
/// @param nftId ID of the NFT, Which get checked corresponds to given `offerId`, Whether it matches the filter or not
/// @param nftAccountOwner Owner of the given `nftId`
///
/// # Returns
/// @return Boolean value, `True` if given `nftId` matches the given `offerId` filters, Otherwise return `False`
///
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