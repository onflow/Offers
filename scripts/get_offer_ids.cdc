import Offers from "../contracts/Offers.cdc"

/// This script returns an array of all the offers created under given account owned `OpenOffers` resource
///
/// # Params
/// @param account Address of the account, Whose offer Id get queried
///
/// # Returns
/// @return Array of Ids
pub fun main(account: Address): [UInt64] {
    let openOfferRef = getAccount(account)
        .getCapability<&Offers.OpenOffers{Offers.OpenOffersPublic}>(
            Offers.OpenOffersPublicPath
        )
        .borrow()
        ?? panic("Could not borrow public open offers resource from address")
    
    return openOfferRef.getOfferIds()
}
