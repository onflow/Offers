import Offers from "../contracts/Offers.cdc"

/// This script is used to fetch all the `OfferCut` receiver addresses
///
/// # Params
/// @param offerId ID of the offer whose `OfferCut` receiver address get queried
/// @param offerOwner Owner of the account which holds the offer resource
/// 
/// # Returns
/// @returns List of the receiver addresses
///
pub fun main(offerId: UInt64, offerOwner: Address) : [Address] {
    let offerRef = getAccount(offerOwner).getCapability<&{Offers.OpenOffersPublic}>(Offers.OpenOffersPublicPath).borrow()! 
    let borrowedOffer = offerRef.borrowOffer(offerId: offerId) ?? panic("Not able to borrowed successfully")
    let offerDetails = borrowedOffer.getDetails()
    var offerCutReceivers: [Address] = []
    for cut in offerDetails.offerCuts {
        offerCutReceivers.append(cut.receiver.borrow()!.owner!.address)
    }
    return offerCutReceivers
}