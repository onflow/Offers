import Offers from "../contracts/Offers.cdc"

/// Return the offer cut receiver addresses
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