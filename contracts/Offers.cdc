import FungibleToken from "./core/FungibleToken.cdc"
import NonFungibleToken from "./core/NonFungibleToken.cdc"
import MetadataViews from "./core/MetadataViews.cdc"
import PaymentHandler from "./PaymentHandler.cdc"
import DefaultPaymentHandler from "./DefaultPaymentHandler.cdc"
import OfferMatcher from "./OfferMatcher.cdc"

/// Offers
///
/// This is a smart contract written in the Cadence smart contract programming language. The intent of this
/// smart contract is to allow "prospective buyers" to show their intent to buy a digital asset, such as an NFT,
/// using any Fungible Token (FT hereof) as the settlement currency.
///
/// Throughout the contract, the term "prospective buyer" refers to the buyer who creates an `Offer` to purchase an NFT,
/// whereas the term "seller" refers to the buyer who accepts the `Offer` or sells its NFT to the prospective buyer.
///
/// Prospective buyers can specify the kind of NFT they want by using different NFT traits or NFT Ids as filters,
/// which are provided as `offerFilters` during the offer creation process.  The `OfferMatcher` contract,
/// on the other hand, would be used to resolve those filters during the purchase or acceptance of the offer.
///
/// When a new offer is created, the contract fires the `OfferStateUpdated` event. Interested marketplaces or dApps
/// can search the FVM logs for similar events and list the offer on their dashboards so that sellers can see available
/// offers in the market. Marketplaces or dApps can earn a fixed commission amount set during the creation of an offer 
/// to facilitate the purchase of an offer.
///
/// To provide a revenue stream to the creators of digital assets, the `Offers` contract honours royalty if NFT 
/// implements `MetadataView.RoyaltyView` and transfers respective royalties to royalty receivers during offer 
/// purchase or acceptance. It also simplifies the payment of various service fees as `OfferCut`.
///  
pub contract Offers {

    /// RevenutType
    pub enum RevenueType : UInt8 {
        pub case OFFER_CUT
        pub case ROYALTY
    }

    /// OfferState
    /// Enum tells the different state of `Offer` during its complete lifecycle
    pub enum OfferState : UInt8 {
        pub case AVAILABLE
        pub case ACCEPTED
        pub case DESTROYED
    }

    /// Emitted when the `OpenOffers` resource gets destroyed.
    pub event OpenOffersDestroyed(openOffersResourceID: UInt64)

    /// Emitted when the `OpenOffers` resource gets created.
    pub event OpenOffersInitialized(OpenOffersResourceId: UInt64)

    /// OfferStateUpdated
    /// Emitted whenever the `Offer` moves into different state of its lifecycle
    ///
    pub event OfferStateUpdated(
        offerState: UInt8,
        offerAddress: Address,
        offerId: UInt64,
        nftType: Type,
        maximumOfferAmount: UFix64,
        offerType: String,
        offerFilterNames: [String],
        commissionAmount: UFix64,
        allowedCommissionReceivers: [Address]?,
        paymentVaultType: Type,
        offerCuts: [ReceiverAndAmount],
        nftId: UInt64?,
        paidOfferCuts: [ReceiverAndAmount]?,
        paidRoyalties: [ReceiverAndAmount]?,
        acceptingAddress: Address?,
        commissionReceiver: Address?,
    )

    /// UnpaidRevenueSplit
    /// During acceptance of the offer, when revenue wouldn't get paid
    ///
    pub event UnpaidRevenueSplit(to: Address, amount: UFix64, revenueType: UInt8)

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

    /// ReceiverAndAmount
    /// Datatype to represent the receiver of funds in terms of `receiver` address
    /// which actually receive funds and `amount` represents the number of FungibleTokens
    /// received.
    pub struct ReceiverAndAmount {
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

    /// PaymentProviderGuard
    /// Provides basic spend control guard around the enclosed payment provider capability, set using `allowedWithdrawableBalance`
    pub struct PaymentProviderGuard {
        /// Holds the provider capability, It is consumed when funds are withdrawn to pay for the NFT purchase.
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
            return self.providerCap.borrow()!.getType()
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
    /// Convenience type holding the FungibleToken.Receiver and amount. This metadata is
    /// accessed at time of sale, making it possible for the seller to transact directly with the offering account
    ///
    pub struct OfferCut {
        /// The receiver for the payment.
        /// Note that we do not store an address to find the Vault that this represents,
        /// as the link or resource that we fetch in this way may be manipulated,
        /// so to find the address that a cut goes to you must get this struct and then
        /// call receiver.borrow()!.owner!.address on it.
        /// This can be done efficiently in a script. e.g. - `get_offer_cut_receiver_addresses.cdc`
        pub let receiver: Capability<&{FungibleToken.Receiver}>

        /// The amount of FungibleTokens that will be paid to the Sellers receiver when they accept the Offer. 
        pub let amount: UFix64

        /// initializer
        ///
        init(receiver: Capability<&{FungibleToken.Receiver}>, amount: UFix64) {
            self.receiver = receiver
            self.amount = amount
        }

        /// Allow to converts the `OfferCut` into `ReceiverAndAmount`.
        pub fun into(): ReceiverAndAmount {
            return ReceiverAndAmount(
                receiver: self.receiver.borrow()!.owner!.address,
                amount: self.amount
            )
        }
    }

    /// OfferDetails
    /// A struct to contain Offers metadata which define the criteria to match
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
        /// Commission provided when offer gets consumed
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
    /// The public interface to an Offer resource.
    ///
    pub resource interface OfferPublic {
        /// accept
        /// Below function would be used by the seller of the NFT to accept the offer.
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

        /// calcNetPaymentToSeller
        /// Return the amount of fungible tokens will be received by the offeree
        ///
        pub fun calcNetPaymentToSeller(item: &{MetadataViews.Resolver}): UFix64

        /// getValidOfferFilterTypes
        /// Return the supported filter types
        ///
        pub fun getValidOfferFilterTypes(): {String: String}

        /// doesGivenItemMatchOffer
        /// Checks whether the given item respect the provided offer or not.
        ///
        pub fun doesGivenItemMatchOffer(item: &AnyResource{NonFungibleToken.INFT, MetadataViews.Resolver}): Bool

        /// getAllowedCommissionReceivers
        /// Fetches the allowed marketplaces capabilities or commission receivers.
        /// If this returns a `nil` value it means the Offer specifies no commission receivers.
        /// In this case the signer may use their own address to collect available commissions 
        /// since no constraint was declared.
        ///
        pub fun getAllowedCommissionReceivers(): [Capability<&{FungibleToken.Receiver}>]?

        /// getOfferMatcherCapability
        /// Return the offer matcher capability
        ///
        pub fun getOfferMatcherCapability(): Capability<&{OfferMatcher.OfferMatcherPublic}>

        /// getPaymentHandlerCapability
        /// Return the payment handler capability
        ///
        pub fun getPaymentHandlerCapability(): Capability<&{PaymentHandler.PaymentHandlerPublic}>
    }


    pub resource Offer: OfferPublic {
        /// The OfferDetails struct of the Offer
        access(self) let details: OfferDetails
        /// The vault which will handle the payment if the Offer is accepted.
        access(contract) let paymentProviderGuard: PaymentProviderGuard
        /// Receiver address for the NFT when/if the Offer is accepted.
        access(contract) let nftReceiverCapability: Capability<&{NonFungibleToken.Receiver}>
        /// An optional list of capabilities that are approved 
        /// to receive the commission.
        access(contract) let commissionReceivers: [Capability<&{FungibleToken.Receiver}>]?
        /// OfferMatcher capability for the offer type
        access(contract) let matcherCapability: Capability<&{OfferMatcher.OfferMatcherPublic}>
        /// Payment Handler capability, It got use when offer get accepted
        access(contract) let paymentHandlerCapability: Capability<&{PaymentHandler.PaymentHandlerPublic}>

        init(
            paymentProviderGuard: PaymentProviderGuard,
            nftReceiverCapability: Capability<&{NonFungibleToken.Receiver}>,
            nftType: Type,
            maximumOfferAmount: UFix64,
            commissionAmount: UFix64,
            offerCuts: [Offers.OfferCut],
            offerFilters: {String: AnyStruct},
            matcherCapability: Capability<&{OfferMatcher.OfferMatcherPublic}>,
            paymentHandlerCapability: Capability<&{PaymentHandler.PaymentHandlerPublic}>?,
            commissionReceivers: [Capability<&{FungibleToken.Receiver}>]?
        ) {
            pre {
                nftReceiverCapability.check(): "Can not borrow nftReceiverCapability"
                matcherCapability.check(): "Can not borrow matcherCapability"
                maximumOfferAmount == paymentProviderGuard.allowedWithdrawableBalance: "Mismatch in maximum offer amount and allowed withdrawable balance"
            }

            if let handlerCap = paymentHandlerCapability {
                assert(handlerCap.check(), message: "Invalid Payment handler capability provider")
                self.paymentHandlerCapability = handlerCap
            } else {
                // Assign default payment handler capability
                self.paymentHandlerCapability = Offers.DefaultPaymentHandlerCap
            }
            
            self.commissionReceivers = commissionReceivers
            self.paymentProviderGuard = paymentProviderGuard
            self.nftReceiverCapability = nftReceiverCapability
            self.matcherCapability = matcherCapability

            self.details = OfferDetails(
                offerId: self.uuid,
                nftType: nftType,
                maximumOfferAmount: maximumOfferAmount,
                commissionAmount: commissionAmount,
                offerCuts: offerCuts,
                offerFilters: offerFilters,
                paymentVaultType: paymentProviderGuard.getProviderType(),
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

            let resolverCap = self.matcherCapability.borrow() ?? panic("Failed to borrow matcherCapability")
            let nftReceiverCap = self.nftReceiverCapability.borrow() ?? panic("Failed to borrow nftReceiverCapibility")
            let hasMeetingMatcherCriteria = resolverCap.checkOfferMatches(
                item: &item as &{NonFungibleToken.INFT, MetadataViews.Resolver},
                offerFilters: self.details.offerFilters
            )

            var paidOfferCuts: [OfferCut] = []
            var paidRoyalties: [ReceiverAndAmount] = []

            assert(hasMeetingMatcherCriteria, message: "OfferMatcher failed, invalid NFT please check Offer criteria")

            // Withdraw maximum offered amount by the prospective buyer.
            let toBePaidVault <- self.paymentProviderGuard.withdraw()

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

            let effectiveBalanceAfterCommission = toBePaidVault.balance

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
                        emit UnpaidRevenueSplit(to: cut.receiver.address, amount: cut.amount, revenueType: RevenueType.OFFER_CUT.rawValue)
                    }
                    
                }
            }

            let nftId = item.id
            // Check whether the NFT supports the royalties metadataView, If yes then honour the royalties.
            if item.getViews().contains(Type<MetadataViews.Royalties>()) {
                let royaltiesRef = item.resolveView(Type<MetadataViews.Royalties>())?? panic("Unable to retrieve the royalties")
                let royalties = (royaltiesRef as! MetadataViews.Royalties).getRoyalties()
                for royalty in royalties {
                    if let beneficiary = royalty.receiver.borrow() {
                        let royaltyAmount = royalty.cut * effectiveBalanceAfterCommission
                        // Make sure the given royalty reciever capability has the valid type
                        // If reciever doesn't have the valid capability type then their funds will be sent to `recieverCapability`
                        if self.paymentHandlerCapability.borrow()!.checkValidVaultType(receiverCap: royalty.receiver, allowedVaultType: self.details.paymentVaultType) {
                            let royaltyPayment <- toBePaidVault.withdraw(amount: royaltyAmount)
                            beneficiary.deposit(from: <- royaltyPayment)
                            paidRoyalties.append(ReceiverAndAmount(receiver: royalty.receiver.address, amount: royaltyAmount))
                        } else {
                            // Emit Event
                            emit UnpaidRevenueSplit(to: royalty.receiver.address, amount: royaltyAmount, revenueType: RevenueType.ROYALTY.rawValue)
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
            // Desposit the asset to the prospective buyer.
            nftReceiverCap.deposit(token: <- (item as! @NonFungibleToken.NFT))

            emit OfferStateUpdated(
                offerState: OfferState.ACCEPTED.rawValue,
                offerAddress: self.nftReceiverCapability.address,
                offerId: self.details.offerId,
                nftType: self.details.nftType,
                maximumOfferAmount: self.details.maximumOfferAmount,
                offerType: self.details.offerFilters["_type"] as! String? ?? "unknown",
                offerFilterNames: self.details.offerFilters.keys,
                commissionAmount: self.details.commissionAmount,
                allowedCommissionReceivers: Offers.getCommissionReceiverAddresses(commissionReceivers: self.commissionReceivers),
                paymentVaultType: self.details.paymentVaultType,
                offerCuts: Offers.convertIntoReceiverAndAmount(cuts: self.details.offerCuts),
                nftId: nftId,
                paidOfferCuts: Offers.convertIntoReceiverAndAmount(cuts: paidOfferCuts),
                paidRoyalties: paidRoyalties,
                acceptingAddress: receiverCapability.address,
                commissionReceiver: self.details.commissionAmount != 0.0 ? commissionRecipient!.address : nil
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
            return self.matcherCapability.borrow()!.getValidOfferFilterTypes()
        }

        /// calcNetPaymentToSeller
        /// Calculates the amount of fungible tokens that would be received by the Seller for this offer
        ///
        pub fun calcNetPaymentToSeller(item: &{MetadataViews.Resolver}): UFix64 {
            var totalCutPayment: UFix64 = 0.0
            var totalRoyaltyPayment: UFix64 = 0.0
            let effectiveAmountAfterCommission = self.details.maximumOfferAmount - self.details.commissionAmount
            for cut in self.details.offerCuts {
                if let receiver = cut.receiver.borrow() {
                    totalCutPayment = totalCutPayment + cut.amount
                }
            }

            // Check whether the NFT supports the royalties metadataView, If yes then honour the royalties.
            if item.getViews().contains(Type<MetadataViews.Royalties>()) {
                if let royaltiesRef = item.resolveView(Type<MetadataViews.Royalties>()) {
                    let royalties = (royaltiesRef as! MetadataViews.Royalties).getRoyalties()
                    for royalty in royalties {
                        if let recev = royalty.receiver.borrow() {
                            totalRoyaltyPayment = totalRoyaltyPayment + royalty.cut * effectiveAmountAfterCommission
                        }
                    }
                }
            }

            return effectiveAmountAfterCommission - totalRoyaltyPayment - totalCutPayment
        }

        /// getAllowedCommissionReceivers
        /// Fetches the allowed marketplaces capabilities or commission receivers.
        /// If it returns `nil` then commission is up to grab by anyone.
        pub fun getAllowedCommissionReceivers(): [Capability<&{FungibleToken.Receiver}>]? {
            return self.commissionReceivers
        }

        /// Return the matcher capability
        pub fun getOfferMatcherCapability(): Capability<&{OfferMatcher.OfferMatcherPublic}> {
            return self.matcherCapability
        }

        /// Return the payment handler capability
        pub fun getPaymentHandlerCapability(): Capability<&{PaymentHandler.PaymentHandlerPublic}> {
            return self.paymentHandlerCapability
        }

        /// doesGivenItemMatchOffer
        /// Checks whether the given item fulfills the provided offer or not.
        ///
        pub fun doesGivenItemMatchOffer(item: &AnyResource{NonFungibleToken.INFT, MetadataViews.Resolver}): Bool {
            return  self.matcherCapability.check() ? 
                    self.matcherCapability.borrow()!.checkOfferMatches(item: item, offerFilters: self.details.offerFilters) :
                    false
        }

        destroy() {
            if !self.details.accepted {
                emit OfferStateUpdated(
                    offerState: OfferState.DESTROYED.rawValue,
                    offerAddress: self.nftReceiverCapability.address,
                    offerId: self.details.offerId,
                    nftType: self.details.nftType,
                    maximumOfferAmount: self.details.maximumOfferAmount,
                    offerType: self.details.offerFilters["_type"] as! String? ?? "unknown",
                    offerFilterNames: self.details.offerFilters.keys,
                    commissionAmount: self.details.commissionAmount,
                    allowedCommissionReceivers: Offers.getCommissionReceiverAddresses(commissionReceivers: self.commissionReceivers),
                    paymentVaultType: self.details.paymentVaultType,
                    offerCuts: Offers.convertIntoReceiverAndAmount(cuts: self.details.offerCuts),
                    nftId: nil,
                    paidOfferCuts: nil,
                    paidRoyalties: nil,
                    acceptingAddress: nil,
                    commissionReceiver: nil
                )
            }
        }
    }

    /// OpenOffersPublic
    /// An interface providing a useful public interface to interact with OpenOffers.
    ///
    pub resource interface OpenOffersPublic {

        /// getOfferIds
        /// Get a list of Offer ids created by the prospective buyer and hold by the OpenOffers resource.
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

        /// cleanupGhostOffer
        /// Remove an Offer if it is not accepted yet and its provider balance
        /// got below the `allowedWithdrawableBalance`.
        ///
        pub fun cleanupGhostOffer(offerId: UInt64)

        /// getAllOffersDetails
        /// Returns details of all the offers.
        ///
        pub fun getAllOffersDetails(): {UInt64: Offers.OfferDetails}
    }

    /// The concrete OpenOffers Resource implementing OpenOffersPublic resource interface.
    pub resource OpenOffers: OpenOffersPublic {
        /// Dictionary of Offers uuids to Offer resources.
        access(contract) var offers: @{UInt64: Offer}

        /// createOffer
        /// Facilitates the creation of Offer.
        ///
        pub fun createOffer(
            paymentProviderGuard: PaymentProviderGuard,
            nftReceiverCapability: Capability<&{NonFungibleToken.Receiver}>,
            nftType: Type,
            maximumOfferAmount: UFix64,
            commissionAmount: UFix64,
            offerCuts: [Offers.OfferCut],
            offerFilters: {String: AnyStruct},
            matcherCapability: Capability<&{OfferMatcher.OfferMatcherPublic}>,
            paymentHandlerCapability: Capability<&{PaymentHandler.PaymentHandlerPublic}>?,
            commissionReceivers: [Capability<&{FungibleToken.Receiver}>]?
        ): UInt64 {
            let offer <- create Offer(
                paymentProviderGuard: paymentProviderGuard,
                nftReceiverCapability: nftReceiverCapability,
                nftType: nftType,
                maximumOfferAmount: maximumOfferAmount,
                commissionAmount: commissionAmount,
                offerCuts: offerCuts,
                offerFilters: offerFilters,
                matcherCapability: matcherCapability,
                paymentHandlerCapability: paymentHandlerCapability,
                commissionReceivers: commissionReceivers
            )

            let offerResourceID = offer.uuid
            // Add the new offer to the dictionary.
            self.offers[offerResourceID] <-! offer
            
            // Emit event
            emit OfferStateUpdated(
                offerState: OfferState.AVAILABLE.rawValue,
                offerAddress: self.owner?.address!,
                offerId: offerResourceID,
                nftType: nftType,
                maximumOfferAmount: maximumOfferAmount,
                offerType: offerFilters["_type"] as! String? ?? "unknown",
                offerFilterNames: offerFilters.keys,
                commissionAmount: commissionAmount,
                allowedCommissionReceivers: Offers.getCommissionReceiverAddresses(commissionReceivers: commissionReceivers),
                paymentVaultType: paymentProviderGuard.getProviderType(),
                offerCuts: Offers.convertIntoReceiverAndAmount(cuts: offerCuts),
                nftId: nil,
                paidOfferCuts: nil,
                paidRoyalties: nil,
                acceptingAddress: nil,
                commissionReceiver: nil,
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
        ///
        pub fun cleanup(offerId: UInt64) {
            pre {
                self.offers[offerId] != nil: "Offer with given id does not exists"
            }
            let offer <- self.offers.remove(key: offerId)!
            assert(offer.getDetails().accepted, message: "Offer is not accepted, only admin can remove")
            destroy offer
        }

        /// cleanupGhostOffer
        /// Removes an Offer if it is not already accepted and its provider
        /// balance is less then `allowedWithdrawableBalance`
        pub fun cleanupGhostOffer(offerId: UInt64) {
            pre {
                self.offers[offerId] != nil: "Offer with given id does not exists"
            }
            let offer <- self.offers.remove(key: offerId)!
            assert(!offer.getDetails().accepted, message: "Offer is not accepted, only admin can remove")
            assert(offer.paymentProviderGuard.getProviderBalance() >= offer.paymentProviderGuard.allowedWithdrawableBalance, message: "Offer is not ghosted yet")
            destroy offer
        }

        /// destructor
        ///
        destroy () {
            destroy self.offers

            // Emit event notifying that this OpenOffers Resource has been destroyed
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

    /// convertIntoReceiverAndAmount
    /// Helper function to convert the `OfferCut` data type to `ReceiverAndAmount`.
    pub fun convertIntoReceiverAndAmount(cuts: [OfferCut]): [ReceiverAndAmount] {
        var receivers: [ReceiverAndAmount] = []
        for cut in cuts {
            receivers.append(cut.into())
        }
        return receivers
    }

    access(contract) fun getCommissionReceiverAddresses(commissionReceivers: [Capability<&{FungibleToken.Receiver}>]?) : [Address]? {
        var allowedCommissionReceivers : [Address]? = nil
        if let allowedReceivers = commissionReceivers {
            // Small hack here to make `allowedCommissionReceivers` variable compatible to
            // array properties.
            allowedCommissionReceivers = []
            for receiver in allowedReceivers {
                allowedCommissionReceivers!.append(receiver.borrow()!.owner!.address)
            }
        }
        return allowedCommissionReceivers
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
        self.OpenOffersStoragePath = /storage/FlowOpenMarketOffersStandard
        self.OpenOffersPublicPath = /public/FlowOpenMarketOffersStandard
        self.FungibleTokenProviderVaultPath = /private/OffersFungibleTokenProviderVault
    }
}
 