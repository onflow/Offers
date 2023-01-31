import Offers from "../contracts/Offers.cdc"
import OfferMatcher from "../contracts/OfferMatcher.cdc"
import FungibleToken from "../contracts/core/FungibleToken.cdc"
import NonFungibleToken from "../contracts/core/NonFungibleToken.cdc"
import ExampleToken from "../contracts/core/ExampleToken.cdc"
import ExampleNFT from "../contracts/core/ExampleNFT.cdc"

/// Transaction used to propose the offer or in other words, Prospective buyer would use below transaction to create offer
/// for the NFT it likes to buy
///
/// # Params
/// @param nftReceiver Address of the account which is going to receive the NFT once the offer get accepted
/// @param maximumOfferAmount Maximum amount of fungible tokens prospective buyer is willing to pay for acceptance of its offer
/// @param cutReceivers List of addresses who receives cut from the sale of offer
/// @param cuts List of amount sent to the `cutReceivers`.
/// @param offerFilters Filter applied by the offer on the receiving NFT
/// @param matcherRefProvider Address of the contract that provides the matcher for the offer
/// @param commissionAmount Commission amount provided to the facilitator of the purchase of offer
/// @param commissionReceivers List of addresses which are allowed to receive `commissionAmount`. Generally those are marketplaces
/// If its provided value is `nil` then it means anyone in the ecosystem can grab the commission to facilitate the purchase of the offer
transaction(
    nftReceiver: Address,
    maximumOfferAmount: UFix64,
    cutReceivers: [Address],
    cuts:[UFix64],
    offerFilters: {String: AnyStruct},
    matcherRefProvider: Address,
    commissionAmount: UFix64,
    commissionReceivers: [Address]?
) {
    let offerManager: &Offers.OpenOffers{Offers.OfferManager}
    let providerVaultCap: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>
    let nftReceiverCap: Capability<&{NonFungibleToken.Receiver}>
    let matcherCap: Capability<&{OfferMatcher.OfferMatcherPublic}>
    var offerCuts: [Offers.OfferCut]
    var commissionRecevs: [Capability<&{FungibleToken.Receiver}>]

    prepare(acct: AuthAccount) {
        self.offerCuts = []
        self.commissionRecevs = []
        self.offerManager = acct.borrow<&Offers.OpenOffers{Offers.OfferManager}>(from: Offers.OpenOffersStoragePath)
            ?? panic("Given account does not possess OfferManager resource")

        // Check whether the account contains the private capability.
        if acct.getLinkTarget(Offers.FungibleTokenProviderVaultPath) == nil {
            // Create the private capability for fund provider.
            acct.link<&{FungibleToken.Provider, FungibleToken.Balance}>(Offers.FungibleTokenProviderVaultPath, target: ExampleToken.VaultStoragePath)
        }

        // Get the provider vault.
        self.providerVaultCap = acct.getCapability<&{FungibleToken.Provider, FungibleToken.Balance}>(Offers.FungibleTokenProviderVaultPath)

        // Receiver capability for the NFT.
        self.nftReceiverCap = getAccount(nftReceiver).getCapability<&{NonFungibleToken.Receiver}>(ExampleNFT.CollectionPublicPath)
        assert(self.nftReceiverCap.check(), message: "NFT receiver capability does not exists")

        self.matcherCap = getAccount(matcherRefProvider).getCapability<&{OfferMatcher.OfferMatcherPublic}>(OfferMatcher.getOfferMatcherPublicPath())
        assert(self.matcherCap.check(), message: "OfferMatcher capability does not exists")

        var amountToBePaid: UFix64 = 0.0

        for index, receiver in cutReceivers {
            let receiverCap = getAccount(receiver).getCapability<&{FungibleToken.Receiver}>(ExampleToken.ReceiverPublicPath)
            assert(receiverCap.check(), message: "Invalid capability of the cut receiver")
            assert(cuts[index] != 0.0, message: "Zero cut value is not allowed")
            amountToBePaid = amountToBePaid + cuts[index]
            self.offerCuts.append(Offers.OfferCut(
                receiver: receiverCap,
                amount: cuts[index]
            ))
        }
        assert(amountToBePaid + commissionAmount < maximumOfferAmount, message: "Insufficient offer amount")

        // Create array of commissionReceivers
        if let cRecvs = commissionReceivers {
            for receiver in cRecvs {
                let receiverCap = getAccount(receiver).getCapability<&{FungibleToken.Receiver}>(ExampleToken.ReceiverPublicPath)
                assert(receiverCap.check(), message: "Invalid capability of the commission receiver")
                self.commissionRecevs.append(receiverCap)
            }
        }
        log(self.nftReceiverCap.getType())
    }

    pre {
        cutReceivers.length == cuts.length: "Invalid details of the cuts"
    }

    execute {
        let paymentProviderGuard = Offers.PaymentProviderGuard(cap: self.providerVaultCap, withdrawableBalance: maximumOfferAmount)

        self.offerManager.createOffer(
            paymentProviderGuard: paymentProviderGuard,
            nftReceiverCapability: self.nftReceiverCap,
            nftType: Type<@ExampleNFT.NFT>(),
            maximumOfferAmount: maximumOfferAmount,
            commissionAmount: commissionAmount,
            offerCuts: self.offerCuts,
            offerFilters: offerFilters,
            matcherCapability: self.matcherCap,
            paymentHandlerCapability: nil,
            commissionReceivers: self.commissionRecevs.length == 0 ? nil : self.commissionRecevs
        )
    }
}
 