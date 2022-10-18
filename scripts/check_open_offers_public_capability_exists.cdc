import Offers from "../contracts/Offers.cdc"

pub fun main(target: Address): Bool {
    let capRef = getAccount(target).getCapability<&Offers.OpenOffers{Offers.OpenOffersPublic}>(
        Offers.OpenOffersPublicPath
    )!

    return capRef.check()
}