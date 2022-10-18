import Offers from "../../../../../contracts/Offers.cdc"

// This script returns an array of all the offers created under given account owned OpenOffers resource
// TEST-FRAMEWORK: Because of the cadence test incompetency.

pub fun main(account: Address, index: Int64): UInt64 {
    let openOfferRef = getAccount(account)
        .getCapability<&Offers.OpenOffers{Offers.OpenOffersPublic}>(
            Offers.OpenOffersPublicPath
        )
        .borrow()
        ?? panic("Could not borrow public open offers resource from address")
    
    return openOfferRef.getOfferIds()[index]
}
