import Offers from "../contracts/Offers.cdc"

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