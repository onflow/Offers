import Offers from "../contracts/Offers.cdc"


/// Transaction used to remove the offer resource from the offer account holder
///
/// # Params
/// @param offerId ID of the offer that get removed from the account
transaction(offerId: UInt64) {
    let offerManager: &Offers.OpenOffers{Offers.OfferManager}

    prepare(acct: AuthAccount) {
        self.offerManager = acct.borrow<&Offers.OpenOffers{Offers.OfferManager}>(from: Offers.OpenOffersStoragePath)
            ?? panic("Given account does not possess OfferManager resource")
    }

    execute {
        self.offerManager.removeOffer(offerId: offerId)
    }
}