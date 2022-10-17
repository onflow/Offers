import Offers from "../../../../../contracts/Offers.cdc"
import FungibleToken from "../../../../../contracts/utility/FungibleToken.cdc"
import ExampleToken from "../../../../../contracts/utility/ExampleToken.cdc"

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