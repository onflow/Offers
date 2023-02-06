import Offers from "../contracts/Offers.cdc"

/// This script returns the details for a Offer within a OpenOffer
///
/// # Params
/// @param account Address which holds the `OpenOffers` resource
/// @param offerId ID of the offer resource whose details get queried
///
/// # Returns
/// @return OfferDetails
pub fun main(account: Address, offerId: UInt64): Offers.OfferDetails {
    let openOffersRef = getAccount(account)
        .getCapability<&Offers.OpenOffers{Offers.OpenOffersPublic}>(
            Offers.OpenOffersPublicPath
        )
        .borrow()
        ?? panic("Could not borrow public openOffer from address")

    let offer = openOffersRef.borrowOffer(offerId: offerId)
        ?? panic("No offer with that ID")
    
    return offer.getDetails()
}