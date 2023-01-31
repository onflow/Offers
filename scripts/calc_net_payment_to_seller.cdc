import Offers from "../contracts/Offers.cdc"
import NonFungibleToken from "../contracts/core/NonFungibleToken.cdc"
import MetadataViews from "../contracts/core/MetadataViews.cdc"

/// This script used to tell how much amount that seller receives if it accepts the offer
///
/// # Params
/// @param offerId ID of the offer resource, Which would be accepted by the seller and corresponds to that, Seller receives fungible tokens
/// @param offerCreator Address of the prospective buyer account which created the offer.
/// @param sellerAddress Address of the seller, Who wants to know how much amount it receives if it accepts the provided `offerId`
/// @param nftId ID of the NFT which would be sold to purchase the offer by the seller
/// @param collectionPublicPath Path of the NFT collection that get used to purchase the offer
/// 
/// # Returns
/// @return Amount of fungible token seller receives
///
pub fun main(offerId: UInt64, offerCreator: Address, sellerAddress: Address, nftId: UInt64, collectionPublicPath: PublicPath): UFix64 {
    let openOffersRef = getAccount(offerCreator)
        .getCapability<&Offers.OpenOffers{Offers.OpenOffersPublic}>(
            Offers.OpenOffersPublicPath
        )
        .borrow()
        ?? panic("Could not borrow public openOffer from address")

    let offer = openOffersRef.borrowOffer(offerId: offerId)
        ?? panic("No offer with that ID")
    
    let collectionRef = getAccount(sellerAddress)
        .getCapability(collectionPublicPath)
        .borrow<&{NonFungibleToken.CollectionPublic,  MetadataViews.ResolverCollection}>()
        ?? panic("Could not borrow capability from public collection at specified path")
    let item = collectionRef.borrowViewResolver(id: nftId)
    return offer.calcNetPaymentToSeller(item: item)
}   