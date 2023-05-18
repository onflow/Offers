import Offers from "../contracts/Offers.cdc"


/// Transaction used to remove the offer resource from the offer account holder
///
/// # Params
/// @param offerId ID of the offer that get removed from the account
transaction(offerId: UInt64) {
    let openOffersManager: &Offers.OpenOffers

    prepare(acct: AuthAccount) {
        self.openOffersManager = acct.borrow<&Offers.OpenOffers>(from: Offers.OpenOffersStoragePath)
            ?? panic("Given account does not possess OpenOffers resource")
    }

    execute {
        self.openOffersManager.removeOffer(offerId: offerId)
    }
}