import Offers from "../contracts/Offers.cdc"
import NonFungibleToken from "../contracts/utility/NonFungibleToken.cdc"
import MetadataViews from "../contracts/utility/MetadataViews.cdc"

/// It allows to tell how much amount that offeree receives if it accepts offer of offeror
pub fun main(offerId: UInt64, offerCreator: Address, offereeAddress: Address, nftId: UInt64, collectionPublicPath: PublicPath): UFix64 {
    let openOffersRef = getAccount(offerCreator)
        .getCapability<&Offers.OpenOffers{Offers.OpenOffersPublic}>(
            Offers.OpenOffersPublicPath
        )
        .borrow()
        ?? panic("Could not borrow public openOffer from address")

    let offer = openOffersRef.borrowOffer(offerId: offerId)
        ?? panic("No offer with that ID")
    
    let collectionRef = getAccount(offereeAddress)
        .getCapability(collectionPublicPath)
        .borrow<&{NonFungibleToken.CollectionPublic,  MetadataViews.ResolverCollection}>()
        ?? panic("Could not borrow capability from public collection at specified path")
    let item = collectionRef.borrowViewResolver(id: nftId)
    return offer.getExpectedPaymentToOfferee(item: item)
}   