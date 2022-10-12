import FungibleToken from "./utility/FungibleToken.cdc"
import NonFungibleToken from "./utility/NonFungibleToken.cdc"
import MetadataViews from "./utility/MetadataViews.cdc"
import Resolver from "./Resolver.cdc"

// Offers
//
// Contract holds the Offer resource and a public method to create them.
//
// Each Offer can have one or more royalties of the sale price that
// goes to one or more addresses.
//
// Owners of NFT can watch for `OfferAvailable` events and check
// the Offer amount to see if they wish to accept the offer.
//
// Marketplaces and other aggregators can watch for `OfferAvailable` events
// and list offers of interest to logged in users.
//
pub contract Offers {

    /// Emitted when the `OpenOffers` resoruce get destroyed.
    pub event OpenOffersDestroyed(openOffersResourceID: UInt64)

    /// Emitted when the `OpenOffers` resoruce get created.
    pub event OpenOffersInitialized(OpenOffersResourceId: UInt64)

    // OfferAvailable
    // Emitted when the offer gets created by the offeror
    pub event OfferAvailable(
        openOffersAddress: Address,
        offerId: UInt64,
        nftType: Type,
        maximumOfferAmount: UFix64,
        offerType: String,
        offerParamsString: {String:String},
        offerParamsUFix64: {String:UFix64},
        offerParamsUInt64: {String:UInt64},
        paymentVaultType: Type,
    )

    // OfferCompleted
    // The Offer has been resolved. The offer has either been accepted
    // by offeree, or the offer has been removed and destroyed.
    //
    pub event OfferCompleted(
        purchased: Bool,
        acceptingAddress: Address?,
        offerAddress: Address,
        offerId: UInt64,
        nftType: Type,
        maximumOfferAmount: UFix64,
        offerType: String,
        offerParamsString: {String:String},
        offerParamsUFix64: {String:UFix64},
        offerParamsUInt64: {String:UInt64},
        paymentVaultType: Type,
        nftId: UInt64?,
    )

    /// OpenOffersStoragePath
    /// The location in storage that a OpenOffers resource should be located.
    pub let OpenOffersStoragePath: StoragePath

    /// OpenOffersPublicPath
    /// The public location for a OpenOffers link.
    pub let OpenOffersPublicPath: PublicPath

    /// FungibleTokenProviderVaultPath
    /// The private location for FungibleToken provider vault.
    pub let FungibleTokenProviderVaultPath: PrivatePath

    /// OfferCut
    /// A struct representing a recipient that must be sent a certain amount
    /// of the payment when offeree accepts the offer.
    ///
    pub struct OfferCut {
        /// The receiver for the payment.
        /// Note that we do not store an address to find the Vault that this represents,
        /// as the link or resource that we fetch in this way may be manipulated,
        /// so to find the address that a cut goes to you must get this struct and then
        /// call receiver.borrow()!.owner.address on it.
        /// This can be done efficiently in a script.
        pub let receiver: Capability<&{FungibleToken.Receiver}>

        /// The amount of the payment FungibleToken that will be paid to the receiver.
        pub let amount: UFix64

        /// initializer
        ///
        init(receiver: Capability<&{FungibleToken.Receiver}>, amount: UFix64) {
            self.receiver = receiver
            self.amount = amount
        }
    }

    // OfferDetails
    // A struct containing Offers' data.
    //
    pub struct OfferDetails {
        // The ID of the offer
        pub let offerId: UInt64
        // The Type of the NFT
        pub let nftType: Type
        // The Type of the FungibleToken that payments must be made in.
        pub let paymentVaultType: Type
        // The Offer amount for the NFT
        pub let maximumOfferAmount: UFix64
        // Flag to tracked the purchase state
        pub var purchased: Bool
        // This specifies the division of payment between recipients.
        pub let offerCuts: [OfferCut]
        // Used to hold Offer metadata and offer type information
        pub let offerParamsString: {String: String}
        pub let offerParamsUFix64: {String:UFix64}
        pub let offerParamsUInt64: {String:UInt64}

        // setToPurchased
        // Irreversibly set this offer as purchased.
        //
        access(contract) fun setToPurchased() {
            self.purchased = true
        }

        // Initializer
        //
        init(
            offerId: UInt64,
            nftType: Type,
            maximumOfferAmount: UFix64,
            offerCuts: [OfferCut],
            offerParamsString: {String: String},
            offerParamsUFix64: {String:UFix64},
            offerParamsUInt64: {String:UInt64},
            paymentVaultType: Type,
        ) {
            pre {
                // Validate the length of the offer cuts
                offerCuts.length > 0: "Offer at least have one offer cut recipent"
            }
            self.offerId = offerId
            self.nftType = nftType
            self.maximumOfferAmount = maximumOfferAmount
            self.purchased = false
            self.offerParamsString = offerParamsString
            self.offerParamsUFix64 = offerParamsUFix64
            self.offerParamsUInt64 = offerParamsUInt64
            self.paymentVaultType = paymentVaultType
            self.offerCuts = offerCuts

            // Calculate the total cut amount.
            var totalOfferCuts: UFix64 = 0.0
            // Perform initial check on capabilities, and calculate offer price from cut amounts.
            for cut in self.offerCuts {
                // Make sure we can borrow the receiver.
                // We will check this again when the token is sold.
                cut.receiver.borrow()
                    ?? panic("Cannot borrow receiver")
                // Add the cut amount to the total price
                totalOfferCuts = totalOfferCuts + cut.amount
            }
            assert(maximumOfferAmount > totalOfferCuts, message: "Inappropiate maximum offer amount")
        }
    }

    // OfferPublic
    // An interface providing a useful public interface to an Offer resource.
    //
    pub resource interface OfferPublic {
        // accept
        // This will accept the offer if provided with the NFT id that matches the Offer
        //
        pub fun accept(
            item: @{NonFungibleToken.INFT, MetadataViews.Resolver},
            receiverCapability: Capability<&{FungibleToken.Receiver}>,
        )
        // getDetails
        // Return Offer details
        //
        pub fun getDetails(): OfferDetails
    }


    pub resource Offer: OfferPublic {
        // The OfferDetails struct of the Offer
        access(self) let details: OfferDetails
        // The vault which will handle the payment if the Offer is accepted.
        access(contract) let providerVaultCapability: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>
        // Receiver address for the NFT when/if the Offer is accepted.
        access(contract) let nftReceiverCapability: Capability<&{NonFungibleToken.CollectionPublic}>
        // Resolver capability for the offer type
        access(contract) let resolverCapability: Capability<&{Resolver.ResolverPublic}>

        init(
            providerVaultCapability: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>,
            nftReceiverCapability: Capability<&{NonFungibleToken.CollectionPublic}>,
            nftType: Type,
            maximumOfferAmount: UFix64,
            offerCuts: [Offers.OfferCut],
            offerParamsString: {String:String},
            offerParamsUFix64: {String:UFix64},
            offerParamsUInt64: {String:UInt64},
            resolverCapability: Capability<&{Resolver.ResolverPublic}>,
        ) {
            // TODO : Make sure the provided collection has the same type as given type.
            pre {
                nftReceiverCapability.check(): "Can not borrow nftReceiverCapability"
                providerVaultCapability.check(): "Can not borrow providerVaultCapability"
                resolverCapability.check(): "Can not borrow resolverCapability"
            }
            assert(providerVaultCapability.borrow()!.balance > maximumOfferAmount, message: "Insufficent balance in provided vault")
            
            self.providerVaultCapability = providerVaultCapability
            self.nftReceiverCapability = nftReceiverCapability
            self.resolverCapability = resolverCapability

            self.details = OfferDetails(
                offerId: self.uuid,
                nftType: nftType,
                maximumOfferAmount: maximumOfferAmount,
                offerCuts: offerCuts,
                offerParamsString: offerParamsString,
                offerParamsUFix64: offerParamsUFix64,
                offerParamsUInt64: offerParamsUInt64,
                paymentVaultType: providerVaultCapability.getType(),
            )
        }

        // accept
        // Accept the offer if...
        // - Calling from an Offer that hasn't been purchased/desetoryed.
        // - Provided with a NFT matching the NFT id within the Offer details.
        // - Provided with a NFT matching the NFT Type within the Offer details.
        //
        pub fun accept(
            item: @AnyResource{NonFungibleToken.INFT, MetadataViews.Resolver},
            receiverCapability: Capability<&{FungibleToken.Receiver}>,
        ) {

            pre {
                !self.details.purchased: "Offer has already been purchased"
                item.isInstance(self.details.nftType): "item NFT is not of specified type"
                receiverCapability.check(): "Invalid receiver capability"
            }

            let resolverCap = self.resolverCapability.borrow() ?? panic("Failed to borrow resolverCapability")
            let nftReceiverCap = self.nftReceiverCapability.borrow() ?? panic("Failed to borrow nftReceiverCapibility")
            let providerVaultCap = self.providerVaultCapability.borrow() ?? panic("Failed to borrow providerVaultCapability")
            let hasMeetingResolverCriteria = resolverCap.checkOfferResolver(
                item: &item as &{NonFungibleToken.INFT, MetadataViews.Resolver},
                offerParamsString: self.details.offerParamsString,
                offerParamsUInt64: self.details.offerParamsUInt64,
                offerParamsUFix64: self.details.offerParamsUFix64,
            )

            assert(hasMeetingResolverCriteria, message: "Resolver failed, invalid NFT please check Offer criteria")

            // Withdraw maximum offered amount by the offeror.
            let toBePaidVault <- providerVaultCap.withdraw(amount: self.details.maximumOfferAmount)

            // Settle offer cuts
            for cut in self.details.offerCuts {
                if let receiver = cut.receiver.borrow() {
                    let cutPayment <- toBePaidVault.withdraw(amount: cut.amount)
                    receiver.deposit(from: <- cutPayment)
                }
            }

            let remainingAmount = toBePaidVault.balance
            let nftId = item.id
            // Check whether the NFT supports the royalties metadataView, If yes then honour the royalties.
            if item.getViews().contains(Type<MetadataViews.Royalties>()) {
                let royaltiesRef = item.resolveView(Type<MetadataViews.Royalties>())?? panic("Unable to retrieve the royalties")
                let royalties = (royaltiesRef as! MetadataViews.Royalties).getRoyalties()
                for royalty in royalties {
                    if let beneficiary = royalty.receiver.borrow() {
                        let royaltyPayment <- toBePaidVault.withdraw(amount: royalty.cut * remainingAmount)
                        // Chances of failing the deposit is high as its type is different from the payment vault type
                        beneficiary.deposit(from: <- royaltyPayment)
                    }
                }
            }
            // Pay the remaining amount to the receiver after paying the cuts and the royalties.
            receiverCapability.borrow()!.deposit(from: <- toBePaidVault)
            // Update the storage and mark the offer purchased.
            self.details.setToPurchased()
            // Desposit the asset to the offeror.
            nftReceiverCap.deposit(token: <- (item as! @NonFungibleToken.NFT))

            emit OfferCompleted(
                purchased: self.details.purchased,
                acceptingAddress: receiverCapability.address,
                offerAddress: self.nftReceiverCapability.address,
                offerId: self.details.offerId,
                nftType: self.details.nftType,
                maximumOfferAmount: self.details.maximumOfferAmount,
                offerType: self.details.offerParamsString["_type"] ?? "unknown",
                offerParamsString: self.details.offerParamsString,
                offerParamsUFix64: self.details.offerParamsUFix64,
                offerParamsUInt64: self.details.offerParamsUInt64,
                paymentVaultType: self.details.paymentVaultType,
                nftId: nftId,
            )
        }

        // getDetails
        // Return Offer details
        //
        pub fun getDetails(): OfferDetails {
            return self.details
        }

        // getExpectedPaymentToOfferee
        // Return the amount of fungible tokens will be received by the offeree
        //
        pub fun getExpectedPaymentToOfferee(item: &{NonFungibleToken.INFT, MetadataViews.Resolver}): UFix64 {
            var totalCutPayment: UFix64 = 0.0
            var totalRoyaltyPayment: UFix64 = 0.0
            for cut in self.details.offerCuts {
                if let receiver = cut.receiver.borrow() {
                    totalCutPayment = totalCutPayment + cut.amount
                }
            }

            let remainingAmount = self.details.maximumOfferAmount - totalCutPayment
            // Check whether the NFT supports the royalties metadataView, If yes then honour the royalties.
            if item.getViews().contains(Type<MetadataViews.Royalties>()) {
                if let royaltiesRef = item.resolveView(Type<MetadataViews.Royalties>()) {
                    let royalties = (royaltiesRef as! MetadataViews.Royalties).getRoyalties()
                    for royalty in royalties {
                        if let recev = royalty.receiver.borrow() {
                            totalRoyaltyPayment = totalRoyaltyPayment + royalty.cut * remainingAmount
                        }
                    }
                }
            }

            return self.details.maximumOfferAmount - totalRoyaltyPayment - totalCutPayment
        }

        destroy() {
            if !self.details.purchased {
                emit OfferCompleted(
                    purchased: self.details.purchased,
                    acceptingAddress: nil,
                    offerAddress: self.nftReceiverCapability.address,
                    offerId: self.details.offerId,
                    nftType: self.details.nftType,
                    maximumOfferAmount: self.details.maximumOfferAmount,
                    offerType: self.details.offerParamsString["_type"] ?? "unknown",
                    offerParamsString: self.details.offerParamsString,
                    offerParamsUFix64: self.details.offerParamsUFix64,
                    offerParamsUInt64: self.details.offerParamsUInt64,
                    paymentVaultType: self.details.paymentVaultType,
                    nftId: nil,
                )
            }
        }
    }

    /// To create offers to buy NFTs, One should own
    /// `OfferManager` resource to create and manage the
    /// different offers created by themselves.
    /// Example - If Alice intends to become and offeror then
    /// Alice should hold the OfferManager resource in her account
    /// and using the offerManager resource Alic can create different
    /// offers and manage them like remove an offer.
    pub resource interface OfferManager {

        /// proposeOffer
        /// Facilitates the creation of Offer.
        ///
        pub fun proposeOffer(
            providerVaultCapability: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>,
            nftReceiverCapability: Capability<&{NonFungibleToken.CollectionPublic}>,
            nftType: Type,
            maximumOfferAmount: UFix64,
            offerCuts: [Offers.OfferCut],
            offerParamsString: {String:String},
            offerParamsUFix64: {String:UFix64},
            offerParamsUInt64: {String:UInt64},
            resolverCapability: Capability<&{Resolver.ResolverPublic}>,
        ): UInt64 
        
        /// removeOffer
        /// Allow the OfferManager resource owner to remove the proposed offer.
        ///
        pub fun removeOffer(offerId: UInt64)
    }

    // OpenOffersPublic
    // An interface providing a useful public interface to interact with OfferManager.
    //
    pub resource interface OpenOffersPublic {

        // getOfferIds
        // Get a list of Offer ids created by the offeror and hold by the OfferManager resource.
        //
        pub fun getOfferIds(): [UInt64]

        // borrowOffer
        // Borrow an Offer to either accept the Offer or get details on the Offer.
        //
        pub fun borrowOffer(offerId: UInt64): &Offer{OfferPublic}?

        // cleanup
        // Remove already fullfilled offer.
        //
        pub fun cleanup(offerId: UInt64)
    }

    /// Definition of the APIs offered by the OfferManager resource and OpenOffersPublic.
    pub resource OpenOffers: OfferManager, OpenOffersPublic {
        /// The dictionary of Offers uuids to Offer resources.
        access(contract) var offers: @{UInt64: Offer}

        /// proposeOffer
        /// Facilitates the creation of Offer.
        ///
        pub fun proposeOffer(
            providerVaultCapability: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>,
            nftReceiverCapability: Capability<&{NonFungibleToken.CollectionPublic}>,
            nftType: Type,
            maximumOfferAmount: UFix64,
            offerCuts: [Offers.OfferCut],
            offerParamsString: {String:String},
            offerParamsUFix64: {String:UFix64},
            offerParamsUInt64: {String:UInt64},
            resolverCapability: Capability<&{Resolver.ResolverPublic}>,
        ): UInt64 {
            let offer <- create Offer(
                providerVaultCapability: providerVaultCapability,
                nftReceiverCapability: nftReceiverCapability,
                nftType: nftType,
                maximumOfferAmount: maximumOfferAmount,
                offerCuts: offerCuts,
                offerParamsString: offerParamsString,
                offerParamsUFix64: offerParamsUFix64,
                offerParamsUInt64: offerParamsUInt64,
                resolverCapability: resolverCapability,
            )

            let offerResourceID = offer.uuid
            // Add the new offer to the dictionary.
            let oldOffer <- self.offers[offerResourceID] <- offer
            // Note that oldOffer will always be nil, but we have to handle it.
            destroy oldOffer
            // Emit event
            emit OfferAvailable(
                openOffersAddress: self.owner?.address!,
                offerId: offerResourceID,
                nftType: nftType,
                maximumOfferAmount: maximumOfferAmount,
                offerType: offerParamsString["_type"] ?? "unknown",
                offerParamsString: offerParamsString,
                offerParamsUFix64: offerParamsUFix64,
                offerParamsUInt64: offerParamsUInt64,
                paymentVaultType: providerVaultCapability.getType()
            )
            return offerResourceID
        }

        // removeOffer
        // Remove an Offer that has not yet been accepted from the collection and destroy it.
        //
        pub fun removeOffer(offerId: UInt64) {
            destroy self.offers.remove(key: offerId) ?? panic("Provided offerId does not exists")
        }

        // getOfferIds
        // Returns an array of the Offer resource IDs that are in the collection
        //
        pub fun getOfferIds(): [UInt64] {
            return self.offers.keys
        }

        // borrowOffer
        // Returns a read-only view of the Offer for the given offerId if it is contained by this collection.
        //
        pub fun borrowOffer(offerId: UInt64): &Offer{OfferPublic}? {
            if self.offers[offerId] != nil {
                return &self.offers[offerId] as &Offer{OfferPublic}?
            } else {
                return nil
            }
        }

        // cleanup
        // Remove an Offer *if* it has been accepted.
        // Anyone can call, but at present it only benefits the account owner to do so.
        // Kind purchasers can however call it if they like.
        //
        pub fun cleanup(offerId: UInt64) {
            pre {
                self.offers[offerId] != nil: "could not find Offer with given id"
            }
            let offer <- self.offers.remove(key: offerId)!
            assert(offer.getDetails().purchased, message: "Offer is not purchased, only admin can remove")
            destroy offer
        }

        /// destructor
        ///
        destroy () {
            destroy self.offers

            // Let event consumers know that this openOffers will no longer exist
            emit OpenOffersDestroyed(openOffersResourceID: self.uuid)
        }

        // constructor
        //
        init() {
            self.offers <- {}
            // Let event consumers know that this openOffers will no longer exist.
            emit OpenOffersInitialized(OpenOffersResourceId: self.uuid)
        }
    }

    // createOpenOffers
    // Make creating an OpenOffers publicly accessible.
    //
    pub fun createOpenOffers(): @OpenOffers {
        return <-create OpenOffers()
    }

    init () {
        self.OpenOffersStoragePath = /storage/OpenOffers
        self.OpenOffersPublicPath = /public/OpenOffers
        self.FungibleTokenProviderVaultPath = /private/OffersFungibleTokenProviderVault
    }
}
 