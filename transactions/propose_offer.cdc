import FlowToken from 0x0ae53cb6e3f42a79
import Offers from "../contracts/Offers.cdc"
import Resolver from "../contracts/Resolver.cdc"
import FungibleToken from "../contracts/utility/FungibleToken.cdc"
import NonFungibleToken from "../contracts/utility/NonFungibleToken.cdc"

transaction(nftReceiver: Address, nftCollectionPath: PublicPath, nftType: Type, maximumOfferAmount: UFix64, offerCuts: [Offers.OfferCuts], offerParamsString: {String: String}, resolverRefProvider: Address) {
    let offerManager: &Offers.OpenOffers{Offers.OfferManager}
    let providerVaultCap: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>
    let nftReceiverCap: Capability<&{NonFungibleToken.CollectionPublic}>
    let resolverCap: Capability<&{Resolver.ResolverPublic}>

    pre {
        maximumOfferAmount > 0:  "Offer amount can not be zero"
    }

    prepare(acct: AuthAccount) {
        self.offerManager = acct.borrow<&Offers.OpenOffers{Offers.OfferManager}>(from: Offers.OpenOffersStoragePath)
            ?? panic("Given account does not possess OfferManager resource")

        // Check whether the account contains the private capability.
        if acct.borrow<&{FungibleToken.Provider, FungibleToken.Balance}>(from: Offers.FungibleTokenProviderVaultPath) == nil {
            // Create the private capability for fund provider.
            acct.link<&{FungibleToken.Provider, FungibleToken.Balance}>(Offers.FungibleTokenProviderVaultPath, target: /storage/flowTokenVault)
        }

        // Receiver capability for the NFT.
        self.nftReceiverCap = getAccount(nftReceiver).getCapability<&{NonFungibleToken.CollectionPublic}>(nftCollectionPath)
        assert(self.nftReceiverCap.check(), message: "NFT receiver capability does not exists")
        assert(self.nftReceiverCap.getType() == nftType, message: "Provided nftType does not match with the nft collection")

        self.resolverCap = getAccount(resolverRefProvider).getCapability<&{Resolver.ResolverPublic}>(Resolver.getResolverPublicPath())
        assert(self.resolverCap.check(), message: "Resolver capability does not exists")
    }

    execute {
        self.offerManager.proposeOffer(
            providerVaultCapability: self.providerVaultCap,
            nftReceiverCapability: self.nftReceiverCap,
            nftType: nftType,
            maximumOfferAmount: maximumOfferAmount,
            offerCuts: [OfferCuts],
            offerParamsString: offerParamsString,
            offerParamsUFix64: {},
            offerParamsUInt64: {},
            resolverCapability: Capability<&{Resolver.ResolverPublic}>,
        )
    }
}