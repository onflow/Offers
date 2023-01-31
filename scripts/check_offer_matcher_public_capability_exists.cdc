import OfferMatcher from "../contracts/OfferMatcher.cdc"
import ExampleOfferMatcher from "../contracts/ExampleOfferMatcher.cdc"


/// This script checks whether the given `target` account holds the `OfferMatchPublic` capability or not
///
/// # Params
/// @param target Address of the account that get checked to know whether it holds `OfferMatchPublic` capability or not
///
/// # Return
/// @return Boolean value, `True` if given account holds the capability, otherwise return `False`
pub fun main(target: Address): Bool {
    let capRef = getAccount(target).getCapability<&ExampleOfferMatcher.OpenOfferMatcher{OfferMatcher.OfferMatcherPublic}>(
        OfferMatcher.getOfferMatcherPublicPath()
    )
    return capRef.check()
}