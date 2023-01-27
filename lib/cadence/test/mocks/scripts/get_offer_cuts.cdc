import Offers from "OffersAccount"
import FungibleToken from "CoreContractsAccount"
import ExampleToken from "CoreContractsAccount"

pub fun main(receivers: [Address], amounts: [UFix64]): [Offers.OfferCut] {
    var cuts : [Offers.OfferCut] = []
    assert(receivers.length == amounts.length, message: "Incorrect length")
    for i, receiver in receivers {
        cuts.append(Offers.OfferCut(
            receiver: getAccount(receiver).getCapability<&{FungibleToken.Receiver}>(ExampleToken.ReceiverPublicPath),
            amount: amounts[i]
        ))
    }
    return cuts
}