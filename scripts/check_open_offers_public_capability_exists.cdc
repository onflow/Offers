import Offers from "../contracts/Offers.cdc"


/// This script checks whether the given `target` account holds the `OpenOffersPublic` capability or not
///
/// # Params
/// @param target Address of the account that get checked to know whether it holds `OpenOffersPublic` capability or not
///
/// # Return
/// @return Boolean value, `True` if given account holds the capability, otherwise return `False`
pub fun main(target: Address): Bool {
    let capRef = getAccount(target).getCapability<&Offers.OpenOffers{Offers.OpenOffersPublic}>(
        Offers.OpenOffersPublicPath
    )
    return capRef.check()
}