import FungibleToken from "./utility/FungibleToken.cdc"
import NonFungibleToken from "./utility/NonFungibleToken.cdc"
import MetadataViews from "./utility/MetadataViews.cdc"
import PaymentHandler from "./PaymentHandler.cdc"
import DefaultPaymentHandler from "./DefaultPaymentHandler.cdc"
import Resolver from "./Resolver.cdc"

/// Offers
///
/// Contract holds the Offer resource and a public method to create them.
///
/// Anyone interested in purchasing an asset such as NFT can create an offer resource and express
/// their willingness to purchase the asset at the proposed price. Using the 'Resolver', the offeror
/// can also propose offers with different filters on asset metadata. The Resolver contract provides
/// a generic resource to resolve the applied filter on the proposed offer.
///
/// If the asset supports 'MetadataViews.Royalty' the offer resource will also honour the royalties.
/// The offeror can set a different `OfferCut` to pay the platform fee or any other type of commission.
///
/// NFT owners can keep an eye out for 'OfferAvailable' events for NFTs they own and check the Offer amount
/// to determine whether or not to accept the offer.
///
/// Marketplaces and other aggregators can track 'OfferAvailable' events and display offers of interest to logged-in users.
///
pub contract Offers {

    /// Emitted when the `OpenOffers` resource gets destroyed.
    pub event OpenOffersDestroyed(openOffersResourceID: UInt64)

    /// Emitted when the `OpenOffers` resource gets created.
    pub event OpenOffersInitialized(OpenOffersResourceId: UInt64)

    /// OfferAvailable
    /// Emitted when the offer gets created by the offeror
    pub event OfferAvailable(
        openOffersAddress: Address,
        offerId: UInt64,
        nftType: Type,
        maximumOfferAmount: UFix64,
        offerType: String,
        offerFilterNames: [String],
        commissionAmount: UFix64,
        commissionReceivers: [Address]?,
        paymentVaultType: Type,
        offerCuts: [FundsReceiverInfo]
    )

    /// OfferCompleted
    /// The Offer has been resolved. The offer has either been accepted
    /// by offeree, or the offer has been removed and destroyed.
    ///
    pub event OfferCompleted(
        accepted: Bool,
        acceptingAddress: Address?,
        offerAddress: Address,
        offerId: UInt64,
        nftType: Type,
        maximumOfferAmount: UFix64,
        offerType: String,
        offerFilterNames: [String],
        commissionAmount: UFix64,
        commissionReceiver: Address?,
        paymentVaultType: Type,
        nftId: UInt64?,
        paidOfferCuts: [FundsReceiverInfo],
        paidRoyalties: [FundsReceiverInfo]
    )

    /// OfferCutNotPaid
    /// During acceptance of the offer, when cut wouldn't get paid
    ///
    pub event OfferCutNotPaid(to: Address, amount: UFix64)

    /// RoyaltyNotPaid
    /// During acceptance of the offer, when royalty wouldn't get paid
    ///
    pub event RoyaltyNotPaid(to: Address, amount: UFix64)

    /// OpenOffersStoragePath
    /// The location in storage that a OpenOffers resource should be located.
    pub let OpenOffersStoragePath: StoragePath

    /// OpenOffersPublicPath
    /// The public location for a OpenOffers link.
    pub let OpenOffersPublicPath: PublicPath

    /// FungibleTokenProviderVaultPath
    /// The private location for FungibleToken provider vault.
    pub let FungibleTokenProviderVaultPath: PrivatePath

    /// DefaultPaymentHandlerCap
    /// The default payment handler capability used to settle payment during offer acceptance
    pub let DefaultPaymentHandlerCap: Capability<&{PaymentHandler.PaymentHandlerPublic}>

    /// FundsReceiverInfo
    /// Datatype to represent the receiver of funds in terms of `receiver` address
    /// which actually receive funds and `amount` represents the number of FungibleTokens
    /// received.
    pub struct FundsReceiverInfo {
        /// The receiver for the payment.
        /// To support event emission, address is preferred over capability.
        pub let receiver: Address

        /// The amount of the payment FungibleToken that will be paid to the receiver.
        pub let amount: UFix64

        /// initializer
        ///
        init(receiver: Address, amount: UFix64) {
            self.receiver = receiver
            self.amount = amount
        }
    }

    /// FundProvider
    /// Datatype to wrap the Provider capability for the offer
    /// Offeror can set the `allowedWithdrawableBalance` value so that only limited funds can be withdrawn
    pub struct FundProvider {
        /// Holds the provider capability, It get consume when funds are withdrawn to pay for the NFT purchase.
        access(self) let providerCap: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>
        /// Maximum funds can be withdrawn from the provided capability.
        pub let allowedWithdrawableBalance: UFix64

        /// initializer
        ///
        init(
            cap: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>,
            withdrawableBalance: UFix64
        ) {
            pre {
                cap.check(): "Provider capability is not valid"
                cap.borrow()!.balance >= withdrawableBalance: "Not sufficient withdrawableBalance"
            }
            self.providerCap = cap
            self.allowedWithdrawableBalance = withdrawableBalance
        }

        /// Withdraw funds from the provided capability.
        pub fun withdraw() : @FungibleToken.Vault {
            let providerCapRef = self.providerCap.borrow() ?? panic("Not able to borrow provider capability")
            return <- providerCapRef.withdraw(amount: self.allowedWithdrawableBalance)
        }

        /// Return the type of provider capability
        pub fun getProviderType() : Type {
            return self.providerCap.getType()
        }

        /// Return the provider balance
        pub fun getProviderBalance() : UFix64 {
            if let capRef = self.providerCap.borrow() {
                return capRef.balance
            }
            return 0.0
        }
    }

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

        /// Allow to converts the `OfferCut` into `FundsReceiverInfo`.
        pub fun into(): FundsReceiverInfo {
            return FundsReceiverInfo(
                receiver: self.receiver.address,
                amount: self.amount
            )
        }
    }

    /// OfferDetails
    /// A struct containing Offers' data.
    ///
    pub struct OfferDetails {
        /// The ID of the offer
        pub let offerId: UInt64
        /// The Type of the NFT
        pub let nftType: Type
        /// The Type of the FungibleToken that payments must be made in.
        pub let paymentVaultType: Type
        /// The Offer amount for the NFT
        pub let maximumOfferAmount: UFix64
        /// Flag to tracked the purchase state
        pub var accepted: Bool
        /// This specifies the division of payment between recipients.
        pub let offerCuts: [OfferCut]
        /// Used to hold Offer metadata and offer type information
        pub let offerFilters: {String: AnyStruct}
        /// Commission provided when offer get consumed
        pub let commissionAmount: UFix64

        /// setToAccepted
        /// Irreversibly set this offer as accepted.
        ///
        access(contract) fun setToAccepted() {
            self.accepted = true
        }

        /// Initializer
        ///
        init(
            offerId: UInt64,
            nftType: Type,
            maximumOfferAmount: UFix64,
            commissionAmount: UFix64,
            offerCuts: [OfferCut],
            offerFilters: {String: AnyStruct},
            paymentVaultType: Type,
        ) {
            self.offerId = offerId
            self.nftType = nftType
            self.maximumOfferAmount = maximumOfferAmount
            self.accepted = false
            self.offerFilters = offerFilters
            self.paymentVaultType = paymentVaultType
            self.offerCuts = offerCuts
            self.commissionAmount = commissionAmount

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
            assert(maximumOfferAmount > totalOfferCuts + commissionAmount, message: "Inappropriate maximum offer amount")
        }
    }

    /// OfferPublic
    /// An interface providing a useful public interface to an Offer resource.
    ///
    pub resource interface OfferPublic {
        /// accept
        /// This will accept the offer if provided with the NFT id that matches the Offer
        ///
        pub fun accept(
            item: @{NonFungibleToken.INFT, MetadataViews.Resolver},
            receiverCapability: Capability<&{FungibleToken.Receiver}>,
            commissionRecipient: Capability<&{FungibleToken.Receiver}>?
        )
        /// getDetails
        /// Return Offer details
        ///
        pub fun getDetails(): OfferDetails

        /// getExpectedPaymentToOfferee
        /// Return the amount of fungible tokens will be received by the offeree
        ///
        pub fun getExpectedPaymentToOfferee(item: &{MetadataViews.Resolver}): UFix64

        /// getValidOfferFilterTypes
        /// Return the supported filter types
        ///
        pub fun getValidOfferFilterTypes(): {String: String}

        /// isGivenItemMatchesOffer
        /// Checks whether the given item respect the provided offer or not.
        ///
        pub fun isGivenItemMatchesOffer(item: &AnyResource{NonFungibleToken.INFT, MetadataViews.Resolver}): Bool

        /// getAllowedCommissionReceivers
        /// Fetches the allowed marketplaces capabilities or commission receivers.
        /// If it returns `nil` then commission is up to grab by anyone.
        ///
        pub fun getAllowedCommissionReceivers(): [Capability<&{FungibleToken.Receiver}>]?

        /// getOfferResolverCapability
        /// Return the resolver capability
        ///
        pub fun getOfferResolverCapability(): Capability<&{Resolver.ResolverPublic}>

        /// getPaymentHandlerCapability
        /// Return the payment handler capability
        ///
        pub fun getPaymentHandlerCapability(): Capability<&{PaymentHandler.PaymentHandlerPublic}>
    }


    pub resource Offer: OfferPublic {
        /// The OfferDetails struct of the Offer
        access(self) let details: OfferDetails
        /// The vault which will handle the payment if the Offer is accepted.
        access(contract) let fundProvider: FundProvider
        /// Receiver address for the NFT when/if the Offer is accepted.
        access(contract) let nftReceiverCapability: Capability<&{NonFungibleToken.Receiver}>
        /// An optional list of capabilities that are approved 
        /// to receive the commission.
        access(contract) let commissionReceivers: [Capability<&{FungibleToken.Receiver}>]?
        /// Resolver capability for the offer type
        access(contract) let resolverCapability: Capability<&{Resolver.ResolverPublic}>
        /// Payment Handler capability, It got use when offer get accepted
        access(contract) let paymentHandlerCapability: Capability<&{PaymentHandler.PaymentHandlerPublic}>

        init(
            fundProvider: FundProvider,
            nftReceiverCapability: Capability<&{NonFungibleToken.Receiver}>,
            nftType: Type,
            maximumOfferAmount: UFix64,
            commissionAmount: UFix64,
            offerCuts: [Offers.OfferCut],
            offerFilters: {String: AnyStruct},
            resolverCapability: Capability<&{Resolver.ResolverPublic}>,
            paymentHandlerCapability: Capability<&{PaymentHandler.PaymentHandlerPublic}>?,
            commissionReceivers: [Capability<&{FungibleToken.Receiver}>]?
        ) {
            pre {
                nftReceiverCapability.isInstance(nftType): "Invalid NFT receiver type"
                nftReceiverCapability.check(): "Can not borrow nftReceiverCapability"
                resolverCapability.check(): "Can not borrow resolverCapability"
                maximumOfferAmount == fundProvider.allowedWithdrawableBalance: "Mismatch in maximum offer amount and allowed withdrawable balance"
            }

            if let handlerCap = paymentHandlerCapability {
                assert(handlerCap.check(), message: "Invalid Payment handler capability provider")
                self.paymentHandlerCapability = handlerCap
            } else {
                // Assign default payment handler capability
                self.paymentHandlerCapability = Offers.DefaultPaymentHandlerCap
            }
            
            self.commissionReceivers = commissionReceivers
            self.fundProvider = fundProvider
            self.nftReceiverCapability = nftReceiverCapability
            self.resolverCapability = resolverCapability

            self.details = OfferDetails(
                offerId: self.uuid,
                nftType: nftType,
                maximumOfferAmount: maximumOfferAmount,
                commissionAmount: commissionAmount,
                offerCuts: offerCuts,
                offerFilters: offerFilters,
                paymentVaultType: fundProvider.getProviderType(),
            )
        }

        /// accept
        /// Accept the offer if...
        /// - Calling from an Offer that hasn't been accepted/destroyed.
        /// - Provided with a NFT matching the NFT id within the Offer details.
        /// - Provided with a NFT matching the NFT Type within the Offer details.
        ///
        pub fun accept(
            item: @AnyResource{NonFungibleToken.INFT, MetadataViews.Resolver},
            receiverCapability: Capability<&{FungibleToken.Receiver}>,
            commissionRecipient: Capability<&{FungibleToken.Receiver}>?
        ) {

            pre {
                !self.details.accepted: "Offer has already been accepted"
                item.isInstance(self.details.nftType): "item NFT is not of specified type"
                receiverCapability.check(): "Invalid receiver capability"
            }

            let resolverCap = self.resolverCapability.borrow() ?? panic("Failed to borrow resolverCapability")
            let nftReceiverCap = self.nftReceiverCapability.borrow() ?? panic("Failed to borrow nftReceiverCapibility")
            let hasMeetingResolverCriteria = resolverCap.checkOfferResolver(
                item: &item as &{NonFungibleToken.INFT, MetadataViews.Resolver},
                offerFilters: self.details.offerFilters
            )

            var paidOfferCuts: [OfferCut] = []
            var paidRoyalties: [FundsReceiverInfo] = []

            assert(hasMeetingResolverCriteria, message: "Resolver failed, invalid NFT please check Offer criteria")

            // Withdraw maximum offered amount by the offeror.
            let toBePaidVault <- self.fundProvider.withdraw()

            if self.details.commissionAmount > 0.0 {
                // If commission recipient is nil, Throw panic.
                let commissionReceiver = commissionRecipient ?? panic("Commission recipient can't be nil")
                if self.commissionReceivers != nil {
                    var isCommissionRecipientHasValidType = false
                    var isCommissionRecipientAuthorised = false
                    for cap in self.commissionReceivers! {
                        // Check 1: Should have the same type
                        if cap.getType() == commissionReceiver.getType() {
                            isCommissionRecipientHasValidType = true
                            // Check 2: Should have the valid market address that holds approved capability.
                            if cap.address == commissionReceiver.address && cap.check() {
                                isCommissionRecipientAuthorised = true
                                break
                            }
                        }
                    }
                    assert(isCommissionRecipientHasValidType, message: "Given recipient does not has valid type")
                    assert(isCommissionRecipientAuthorised,   message: "Given recipient has not authorised to receive the commission")
                }

                if self.paymentHandlerCapability.borrow()!.checkValidVaultType(receiverCap: commissionReceiver, allowedVaultType: self.details.paymentVaultType) {
                    let commissionPayment <- toBePaidVault.withdraw(amount: self.details.commissionAmount)
                    let recipient = commissionReceiver.borrow() ?? panic("Unable to borrow the recipent capability")
                    recipient.deposit(from: <- commissionPayment)   
                }
            }

            // Settle offer cuts
            for cut in self.details.offerCuts {
                if let receiver = cut.receiver.borrow() {
                    // Make sure the given cut reciever capability has the valid type
                    // If reciever doesn't have the valid capability type then their funds will be sent to `recieverCapability`
                    if self.paymentHandlerCapability.borrow()!.checkValidVaultType(receiverCap: cut.receiver, allowedVaultType: self.details.paymentVaultType) {
                        let cutPayment <- toBePaidVault.withdraw(amount: cut.amount)
                        receiver.deposit(from: <- cutPayment)
                        paidOfferCuts.append(cut)
                    } else {
                        // Emit Event
                        emit OfferCutNotPaid(to: cut.receiver.address, amount: cut.amount)
                    }
                    
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
                        let royaltyAmount = royalty.cut * remainingAmount
                        // Make sure the given royalty reciever capability has the valid type
                        // If reciever doesn't have the valid capability type then their funds will be sent to `recieverCapability`
                        if self.paymentHandlerCapability.borrow()!.checkValidVaultType(receiverCap: royalty.receiver, allowedVaultType: self.details.paymentVaultType) {
                            let royaltyPayment <- toBePaidVault.withdraw(amount: royaltyAmount)
                            beneficiary.deposit(from: <- royaltyPayment)
                            paidRoyalties.append(FundsReceiverInfo(receiver: royalty.receiver.address, amount: royaltyAmount))
                        } else {
                            // Emit Event
                            emit RoyaltyNotPaid(to: royalty.receiver.address, amount: royaltyAmount)
                        }
                    }
                }
            }
            // Pay the remaining amount to the receiver after paying the cuts and the royalties.
            assert(
                self.paymentHandlerCapability.borrow()!
                .checkValidVaultType(receiverCap: receiverCapability, allowedVaultType: self.details.paymentVaultType),
                message: "Receiver capability has not valid type"
            )
            receiverCapability.borrow()!.deposit(from: <- toBePaidVault)
            // Update the storage and mark the offer accepted.
            self.details.setToAccepted()
            // Desposit the asset to the offeror.
            nftReceiverCap.deposit(token: <- (item as! @NonFungibleToken.NFT))

            emit OfferCompleted(
                accepted: self.details.accepted,
                acceptingAddress: receiverCapability.address,
                offerAddress: self.nftReceiverCapability.address,
                offerId: self.details.offerId,
                nftType: self.details.nftType,
                maximumOfferAmount: self.details.maximumOfferAmount,
                offerType: self.details.offerFilters["_type"] as! String? ?? "unknown",
                offerFilterNames: self.details.offerFilters.keys,
                commissionAmount: self.details.commissionAmount,
                commissionReceiver: self.details.commissionAmount != 0.0 ? commissionRecipient!.address : nil,
                paymentVaultType: self.details.paymentVaultType,
                nftId: nftId,
                paidOfferCuts: Offers.convertIntoFundsReceiver(cuts: paidOfferCuts),
                paidRoyalties: paidRoyalties
            )
        }

        /// getDetails
        /// Return Offer details
        ///
        pub fun getDetails(): OfferDetails {
            return self.details
        }

        /// getValidOfferFilterTypes
        /// Return the supported filter types
        ///
        pub fun getValidOfferFilterTypes(): {String: String} {
            return self.resolverCapability.borrow()!.getValidOfferFilterTypes()
        }

        /// getExpectedPaymentToOfferee
        /// Return the amount of fungible tokens will be received by the offeree
        ///
        pub fun getExpectedPaymentToOfferee(item: &{MetadataViews.Resolver}): UFix64 {
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

        /// getAllowedCommissionReceivers
        /// Fetches the allowed marketplaces capabilities or commission receivers.
        /// If it returns `nil` then commission is up to grab by anyone.
        pub fun getAllowedCommissionReceivers(): [Capability<&{FungibleToken.Receiver}>]? {
            return self.commissionReceivers
        }

        /// Return the resolver capability
        pub fun getOfferResolverCapability(): Capability<&{Resolver.ResolverPublic}> {
            return self.resolverCapability
        }

        /// Return the payment handler capability
        pub fun getPaymentHandlerCapability(): Capability<&{PaymentHandler.PaymentHandlerPublic}> {
            return self.paymentHandlerCapability
        }

        /// isGivenItemMatchesOffer
        /// Checks whether the given item respect the provided offer or not.
        ///
        pub fun isGivenItemMatchesOffer(item: &AnyResource{NonFungibleToken.INFT, MetadataViews.Resolver}): Bool {
            return  self.resolverCapability.check() ? 
                    self.resolverCapability.borrow()!.checkOfferResolver(item: item, offerFilters: self.details.offerFilters) :
                    false
        }

        destroy() {
            if !self.details.accepted {
                emit OfferCompleted(
                    accepted: self.details.accepted,
                    acceptingAddress: nil,
                    offerAddress: self.nftReceiverCapability.address,
                    offerId: self.details.offerId,
                    nftType: self.details.nftType,
                    maximumOfferAmount: self.details.maximumOfferAmount,
                    offerType: self.details.offerFilters["_type"] as! String? ?? "unknown",
                    offerFilterNames: self.details.offerFilters.keys,
                    commissionAmount: self.details.commissionAmount,
                    commissionReceiver: nil,
                    paymentVaultType: self.details.paymentVaultType,
                    nftId: nil,
                    paidOfferCuts: [],
                    paidRoyalties: []
                )
            }
        }
    }

    /// To create offers to buy NFTs, One should own
    /// `OfferManager` resource to create and manage the
    /// different offers created by themselves.
    /// Example - If Alice intends to become and offeror then
    /// Alice should hold the OfferManager resource in her account
    /// and using the offerManager resource Alice can create different
    /// offers and manage them like remove an offer.
    pub resource interface OfferManager {

        /// createOffer
        /// Facilitates the creation of an Offer.
        ///
        pub fun createOffer(
            fundProvider: FundProvider,
            nftReceiverCapability: Capability<&{NonFungibleToken.Receiver}>,
            nftType: Type,
            maximumOfferAmount: UFix64,
            commissionAmount: UFix64,
            offerCuts: [Offers.OfferCut],
            offerFilters: {String: AnyStruct},
            resolverCapability: Capability<&{Resolver.ResolverPublic}>,
            paymentHandlerCapability: Capability<&{PaymentHandler.PaymentHandlerPublic}>?,
            commissionReceivers: [Capability<&{FungibleToken.Receiver}>]?
        ): UInt64 
        
        /// removeOffer
        /// Allow the OfferManager resource owner to remove the proposed offer.
        ///
        pub fun removeOffer(offerId: UInt64)
    }

    /// OpenOffersPublic
    /// An interface providing a useful public interface to interact with OfferManager.
    ///
    pub resource interface OpenOffersPublic {

        /// getOfferIds
        /// Get a list of Offer ids created by the offeror and hold by the OfferManager resource.
        ///
        pub fun getOfferIds(): [UInt64]

        /// borrowOffer
        /// Borrow an Offer to either accept the Offer or get details on the Offer.
        ///
        pub fun borrowOffer(offerId: UInt64): &Offer{OfferPublic}?

        /// cleanup
        /// Remove already fulfilled offer.
        ///
        pub fun cleanup(offerId: UInt64)

        /// cleanupGhostOffers
        /// Remove an Offer if it is not accepted yet and its provider balance
        /// got below the `allowedWithdrawableBalance`.
        ///
        pub fun cleanupGhostOffers(offerId: UInt64)

        /// getAllOffersDetails
        /// Returns details of all the offers.
        ///
        pub fun getAllOffersDetails(): {UInt64: Offers.OfferDetails}
    }

    /// Definition of the APIs offered by the OfferManager resource and OpenOffersPublic.
    pub resource OpenOffers: OfferManager, OpenOffersPublic {
        /// The dictionary of Offers uuids to Offer resources.
        access(contract) var offers: @{UInt64: Offer}

        /// createOffer
        /// Facilitates the creation of Offer.
        ///
        pub fun createOffer(
            fundProvider: FundProvider,
            nftReceiverCapability: Capability<&{NonFungibleToken.Receiver}>,
            nftType: Type,
            maximumOfferAmount: UFix64,
            commissionAmount: UFix64,
            offerCuts: [Offers.OfferCut],
            offerFilters: {String: AnyStruct},
            resolverCapability: Capability<&{Resolver.ResolverPublic}>,
            paymentHandlerCapability: Capability<&{PaymentHandler.PaymentHandlerPublic}>?,
            commissionReceivers: [Capability<&{FungibleToken.Receiver}>]?
        ): UInt64 {
            let offer <- create Offer(
                fundProvider: fundProvider,
                nftReceiverCapability: nftReceiverCapability,
                nftType: nftType,
                maximumOfferAmount: maximumOfferAmount,
                commissionAmount: commissionAmount,
                offerCuts: offerCuts,
                offerFilters: offerFilters,
                resolverCapability: resolverCapability,
                paymentHandlerCapability: paymentHandlerCapability,
                commissionReceivers: commissionReceivers
            )

            let offerResourceID = offer.uuid
            // Add the new offer to the dictionary.
            self.offers[offerResourceID] <-! offer

            // Scraping addresses from the capabilities to emit in the event.
            var allowedCommissionReceivers : [Address]? = nil
            if let allowedReceivers = commissionReceivers {
                // Small hack here to make `allowedCommissionReceivers` variable compatible to
                // array properties.
                allowedCommissionReceivers = []
                for receiver in allowedReceivers {
                    allowedCommissionReceivers!.append(receiver.address)
                }
            }
            
            // Emit event
            emit OfferAvailable(
                openOffersAddress: self.owner?.address!,
                offerId: offerResourceID,
                nftType: nftType,
                maximumOfferAmount: maximumOfferAmount,
                offerType: offerFilters["_type"] as! String? ?? "unknown",
                offerFilterNames: offerFilters.keys,
                commissionAmount: commissionAmount,
                commissionReceivers: allowedCommissionReceivers,
                paymentVaultType: fundProvider.getProviderType(),
                offerCuts: Offers.convertIntoFundsReceiver(cuts: offerCuts)
            )
            return offerResourceID
        }

        /// removeOffer
        /// Remove an Offer that has not yet been accepted from the collection and destroy it.
        ///
        pub fun removeOffer(offerId: UInt64) {
            destroy self.offers.remove(key: offerId) ?? panic("Provided offerId does not exist")
        }

        /// getOfferIds
        /// Returns an array of the Offer resource IDs that are in the collection
        ///
        pub fun getOfferIds(): [UInt64] {
            return self.offers.keys
        }

        /// borrowOffer
        /// Returns a read-only view of the Offer for the given offerId if it is contained by this collection.
        ///
        pub fun borrowOffer(offerId: UInt64): &Offer{OfferPublic}? {
            if self.offers[offerId] != nil {
                return &self.offers[offerId] as &Offer{OfferPublic}?
            } else {
                return nil
            }
        }

        /// getAllOffersDetails
        /// Returns details of all the offers.
        pub fun getAllOffersDetails(): {UInt64: Offers.OfferDetails} {
            var offersDetails: {UInt64: Offers.OfferDetails} = {}
            for offerId in self.offers.keys {
                if let borrowedOffer = self.borrowOffer(offerId: offerId) {
                    offersDetails.insert(key: offerId, borrowedOffer.getDetails())
                }
            }
            return offersDetails
        }

        /// cleanup
        /// Remove an Offer *if* it has been accepted.
        /// Anyone can call, but at present it only benefits the account owner to do so.
        /// Kind purchasers can however call it if they like.
        ///
        pub fun cleanup(offerId: UInt64) {
            pre {
                self.offers[offerId] != nil: "Offer with given id does not exists"
            }
            let offer <- self.offers.remove(key: offerId)!
            assert(offer.getDetails().accepted, message: "Offer is not accepted, only admin can remove")
            destroy offer
        }

        /// cleanupGhostOffers
        /// Remove an Offer if it is not accepted yet and its provider balance
        /// got below the `allowedWithdrawableBalance`.
        pub fun cleanupGhostOffers(offerId: UInt64) {
            pre {
                self.offers[offerId] != nil: "Offer with given id does not exists"
            }
            let offer <- self.offers.remove(key: offerId)!
            assert(!offer.getDetails().accepted, message: "Offer is not accepted, only admin can remove")
            assert(offer.fundProvider.getProviderBalance() >= offer.fundProvider.allowedWithdrawableBalance, message: "Offer is not ghosted yet")
            destroy offer
        }

        /// destructor
        ///
        destroy () {
            destroy self.offers

            // Let event consumers know that this openOffers will no longer exist
            emit OpenOffersDestroyed(openOffersResourceID: self.uuid)
        }

        /// constructor
        ///
        init() {
            self.offers <- {}
            // Let event consumers know that this openOffers will no longer exist.
            emit OpenOffersInitialized(OpenOffersResourceId: self.uuid)
        }
    }

    /// createOpenOffers
    /// Make creating an OpenOffers publicly accessible.
    ///
    pub fun createOpenOffers(): @OpenOffers {
        return <-create OpenOffers()
    }

    /// convertIntoFundsReceiver
    /// Helper function to convert the `OfferCut` data type to `FundsReceiverInfo`.
    pub fun convertIntoFundsReceiver(cuts: [OfferCut]): [FundsReceiverInfo] {
        var receivers: [FundsReceiverInfo] = []
        for cut in cuts {
            receivers.append(cut.into())
        }
        return receivers
    }

    init () {
        self.account.save(<-DefaultPaymentHandler.createDefaultHandler(), to: DefaultPaymentHandler.DefaultPaymentHandlerStoragePath)
        // Create a public capability to the stored DefaultHandler that exposes
        // the `checkValidVaultType` method through the `PaymentHandler.PaymentHandlerPublic` interface.
        self.account.link<&{PaymentHandler.PaymentHandlerPublic}>(
            PaymentHandler.getPaymentHandlerPublicPath(),
            target: DefaultPaymentHandler.DefaultPaymentHandlerStoragePath
        )
        self.DefaultPaymentHandlerCap = self.account.getCapability<&{PaymentHandler.PaymentHandlerPublic}>(PaymentHandler.getPaymentHandlerPublicPath())
        self.OpenOffersStoragePath = /storage/OpenOffers
        self.OpenOffersPublicPath = /public/OpenOffers
        self.FungibleTokenProviderVaultPath = /private/OffersFungibleTokenProviderVault
    }
}
 