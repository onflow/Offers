import Offers from "OffersAccount"

transaction(offerId: UInt64, openOfferOwner: Address) {

    prepare(signer: AuthAccount) {

        let openOfferRef = getAccount(openOfferOwner)
            .getCapability<&{Offers.OpenOffersPublic}>(Offers.OpenOffersPublicPath)
            .borrow()
            ?? panic("Unable to borrow the OpenOffersPublic resource")

        openOfferRef.cleanupGhostOffer(offerId: offerId)
    }
}