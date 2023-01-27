import Offers from "OffersAccount"

pub fun main(target: Address): Bool {
    let capRef = getAccount(target).getCapability<&Offers.OpenOffers{Offers.OpenOffersPublic}>(
        Offers.OpenOffersPublicPath
    )!

    return capRef.check()
}