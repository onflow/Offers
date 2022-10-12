import Offers from "../contracts/Offers.cdc"
import Resolver from "../contracts/Resolver.cdc"
import FungibleToken from "../contracts/utility/FungibleToken.cdc"
import NonFungibleToken from "../contracts/utility/NonFungibleToken.cdc"
import ExampleToken from "../contracts/utility/ExampleToken.cdc"
import ExampleNFT from "../contracts/utility/ExampleNFT.cdc"

// This version of transaction is implemented because cadence test framework doesn't support importing of contract.

transaction(nftReceiver: Address, maximumOfferAmount: UFix64, offerCuts: [Offers.OfferCut], offerParamsString: {String: String}, resolverRefProvider: Address) {
    let offerManager: &Offers.OpenOffers{Offers.OfferManager}
    let providerVaultCap: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>
    let nftReceiverCap: Capability<&{NonFungibleToken.CollectionPublic}>
    let resolverCap: Capability<&{Resolver.ResolverPublic}>

    prepare(acct: AuthAccount) {
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
        self.nftReceiverCap = getAccount(nftReceiver).getCapability<&{NonFungibleToken.CollectionPublic}>(ExampleNFT.CollectionPublicPath)
        assert(self.nftReceiverCap.check(), message: "NFT receiver capability does not exists")

        self.resolverCap = getAccount(resolverRefProvider).getCapability<&{Resolver.ResolverPublic}>(Resolver.getResolverPublicPath())
        assert(self.resolverCap.check(), message: "Resolver capability does not exists")
    }

    pre {
        maximumOfferAmount > 0.0:  "Offer amount can not be zero"
    }

    execute {
        self.offerManager.proposeOffer(
            providerVaultCapability: self.providerVaultCap,
            nftReceiverCapability: self.nftReceiverCap,
            nftType: self.nftReceiverCap.getType(),
            maximumOfferAmount: maximumOfferAmount,
            offerCuts: offerCuts,
            offerParamsString: offerParamsString,
            offerParamsUFix64: {},
            offerParamsUInt64: {},
            resolverCapability: self.resolverCap
        )
    }
}