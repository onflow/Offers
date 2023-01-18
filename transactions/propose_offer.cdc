import Offers from "../contracts/Offers.cdc"
import Resolver from "../contracts/Resolver.cdc"
import FungibleToken from "../contracts/core/FungibleToken.cdc"
import NonFungibleToken from "../contracts/core/NonFungibleToken.cdc"
import ExampleToken from "../contracts/core/ExampleToken.cdc"
import ExampleNFT from "../contracts/core/ExampleNFT.cdc"

/// This version of transaction is implemented because cadence test framework doesn't support importing of contract.
transaction(
    nftReceiver: Address,
    maximumOfferAmount: UFix64,
    cutReceivers: [Address],
    cuts:[UFix64],
    offerFilters: {String: AnyStruct},
    resolverRefProvider: Address,
    commissionAmount: UFix64,
    commissionReceivers: [Address]?
) {
    let offerManager: &Offers.OpenOffers{Offers.OfferManager}
    let providerVaultCap: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>
    let nftReceiverCap: Capability<&{NonFungibleToken.Receiver}>
    let resolverCap: Capability<&{Resolver.ResolverPublic}>
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

        self.resolverCap = getAccount(resolverRefProvider).getCapability<&{Resolver.ResolverPublic}>(Resolver.getResolverPublicPath())
        assert(self.resolverCap.check(), message: "Resolver capability does not exists")

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
        let fundProvider = Offers.FundProvider(cap: self.providerVaultCap, withdrawableBalance: maximumOfferAmount)

        self.offerManager.createOffer(
            fundProvider: fundProvider,
            nftReceiverCapability: self.nftReceiverCap,
            nftType: Type<@ExampleNFT.NFT>(),
            maximumOfferAmount: maximumOfferAmount,
            commissionAmount: commissionAmount,
            offerCuts: self.offerCuts,
            offerFilters: offerFilters,
            resolverCapability: self.resolverCap,
            paymentHandlerCapability: nil,
            commissionReceivers: self.commissionRecevs.length == 0 ? nil : self.commissionRecevs
        )
    }
}
 