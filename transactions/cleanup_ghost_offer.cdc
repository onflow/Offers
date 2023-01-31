import Offers from "../contracts/Offers.cdc"

/// Transaction used to cleanup the offer that marked as ghost offer
///
/// # Params
/// @param offerId ID of the offer resource that get cleaned up because it become ghost offer
/// @param openOfferOwner Address of the account which owns the given `offerId` resoruce
transaction(offerId: UInt64, openOfferOwner: Address) {

    prepare(signer: AuthAccount) {

        let openOfferRef = getAccount(openOfferOwner)
            .getCapability<&{Offers.OpenOffersPublic}>(Offers.OpenOffersPublicPath)
            .borrow()
            ?? panic("Unable to borrow the OpenOffersPublic resource")

        openOfferRef.cleanupGhostOffer(offerId: offerId)
    }
}