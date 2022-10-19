import Test

pub var blockchain = Test.newEmulatorBlockchain()
pub var accounts: {String: Test.Account} = {}

pub struct CustomOfferCut {
    pub let receiver: Address
    pub let amount: UFix64

    /// initializer
    ///
    init(receiver: Address, amount: UFix64) {
        self.receiver = receiver
        self.amount = amount
    }
}

// Hack to access the data type of Offers contract
pub struct CustomOfferDetails {
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
    pub let offerCuts: [CustomOfferCut]
    // Used to hold Offer metadata and offer type information
    pub let offerParamsString: {String: String}
    pub let offerParamsUFix64: {String:UFix64}
    pub let offerParamsUInt64: {String:UInt64}

    init(   
        offerId: UInt64,
        nftType: Type,
        maximumOfferAmount: UFix64,
        offerCuts: [CustomOfferCut],
        offerParamsString: {String: String},
        offerParamsUFix64: {String:UFix64},
        offerParamsUInt64: {String:UInt64},
        paymentVaultType: Type,
        purchased: Bool
    ) {
        self.offerId = offerId
        self.nftType = nftType
        self.maximumOfferAmount = maximumOfferAmount
        self.purchased = purchased
        self.offerParamsString = offerParamsString
        self.offerParamsUFix64 = offerParamsUFix64
        self.offerParamsUInt64 = offerParamsUInt64
        self.paymentVaultType = paymentVaultType
        self.offerCuts = offerCuts
    }
}

pub fun setup() {

    // Setup accounts for the smart contract.
    let offers = blockchain.createAccount()
    let resolver = blockchain.createAccount()
    let exampleOfferResolver = resolver
    let nft = blockchain.createAccount()
    let metadataViews = blockchain.createAccount()
    let fungibleToken = blockchain.createAccount()
    let nonFungibleToken = blockchain.createAccount()
    let offeree = blockchain.createAccount()
    let token = blockchain.createAccount()
    let cutReceiver1 = blockchain.createAccount()
    let cutReceiver2 = blockchain.createAccount()
    let offerAcceptor = blockchain.createAccount()
    let royaltyReceiver1 = blockchain.createAccount()
    let royaltyReceiver2 = blockchain.createAccount()


    accounts = {
        "FungibleToken": fungibleToken,
        "NonFungibleToken": nonFungibleToken,
        "MetadataViews": metadataViews,
        "ExampleToken": token,
        "ExampleNFT": nft,
        "Resolver": resolver,
        "ExampleOfferResolver": resolver,
        "Offers": offers,
        "offeree": offeree,
        "offerAcceptor": offerAcceptor,
        "royaltyReceiver1": royaltyReceiver1,
        "royaltyReceiver2": royaltyReceiver2,
        "cutReceiver1": cutReceiver1,
        "cutReceiver2": cutReceiver2
    }
    
    // Let the CLI know how the above addresses are mapped to the contracts.
    blockchain.useConfiguration(Test.Configuration({
        "./FungibleToken.cdc":accounts["FungibleToken"]!.address,
        "./NonFungibleToken.cdc":accounts["NonFungibleToken"]!.address,
        "./MetadataViews.cdc":accounts["MetadataViews"]!.address,
        "./utility/FungibleToken.cdc":accounts["FungibleToken"]!.address,
        "./utility/NonFungibleToken.cdc":accounts["NonFungibleToken"]!.address,
        "./utility/MetadataViews.cdc":accounts["MetadataViews"]!.address,
        "./Resolver.cdc":accounts["Resolver"]!.address,
        "../contracts/Offers.cdc": accounts["Offers"]!.address,
        "../contracts/Resolver.cdc": accounts["Resolver"]!.address,
        "../contracts/ExampleOfferResolver.cdc": accounts["ExampleOfferResolver"]!.address,
        "../contracts/utility/FungibleToken.cdc": accounts["FungibleToken"]!.address,
        "../contracts/utility/NonFungibleToken.cdc": accounts["NonFungibleToken"]!.address,
        "../contracts/utility/ExampleToken.cdc": accounts["ExampleToken"]!.address,
        "../contracts/utility/ExampleNFT.cdc": accounts["ExampleNFT"]!.address,
        "../contracts/utility/MetadataViews.cdc": accounts["MetadataViews"]!.address,
        "../../../../../contracts/utility/FungibleToken.cdc": accounts["FungibleToken"]!.address,
        "../../../../../contracts/utility/ExampleToken.cdc": accounts["ExampleToken"]!.address,
        "../../../../../contracts/utility/MetadataViews.cdc": accounts["MetadataViews"]!.address,
        "../../../../../contracts/utility/NonFungibleToken.cdc": accounts["NonFungibleToken"]!.address,
        "../../../../../contracts/utility/ExampleNFT.cdc": accounts["ExampleNFT"]!.address,
        "../../../../../contracts/Offers.cdc": accounts["Offers"]!.address,
        "../../contracts/utility/NonFungibleToken.cdc": accounts["NonFungibleToken"]!.address,
        "../../contracts/utility/ExampleNFT.cdc": accounts["ExampleNFT"]!.address
    }))

    deploySmartContract(blockchain, "FungibleToken", accounts["FungibleToken"]!, "../../../contracts/utility/FungibleToken.cdc")
    deploySmartContract(blockchain, "NonFungibleToken", accounts["NonFungibleToken"]!, "../../../contracts/utility/NonFungibleToken.cdc")
    deploySmartContract(blockchain, "MetadataViews", accounts["MetadataViews"]!, "../../../contracts/utility/MetadataViews.cdc")
    deploySmartContract(blockchain, "ExampleToken", accounts["ExampleToken"]!, "../../../contracts/utility/ExampleToken.cdc")
    deploySmartContract(blockchain, "ExampleNFT", accounts["ExampleNFT"]!, "../../../contracts/utility/ExampleNFT.cdc")
    deploySmartContract(blockchain, "Resolver", accounts["Resolver"]!, "../../../contracts/Resolver.cdc")
    deploySmartContract(blockchain, "ExampleOfferResolver", accounts["ExampleOfferResolver"]!, "../../../contracts/ExampleOfferResolver.cdc")
    deploySmartContract(blockchain, "Offers", accounts["Offers"]!, "../../../contracts/Offers.cdc")
}

//////////////
/// Test Cases
//////////////


pub fun testCreateOpenOffers() {
    // Execute transaction
    executeSetupAccountTx(accounts["offeree"]!)
    // Verify the transaction effects by calling script
    assert(
        checkAccountHasOpenOffersPublicCapability(accounts["offeree"]!.address),
        message: "Given account doesn't hold the OpenOffers resoource"
    )
}

pub fun testFailToProposeOfferBecauseAccountDoesNotHaveOpenOffersResource() {
    let fakeOfferee = blockchain.createAccount()
    executeProposeOfferTx(
        fakeOfferee,
        fakeOfferee.address,
        10.0,
        [],
        [],
        {},
        fakeOfferee.address,
        "Given account does not possess OfferManager resource"
    )
}

pub fun testFailToProposeOfferBecauseAccountDoesNotHaveNFTReceiverCapability() {
    let offeree = accounts["offeree"]!
    // Setup Token vault and top up with some tokens
    executeSetupVaultAndMintTokensTx(offeree, 1000.0)
    // Execute proposeOffer transaction
    executeProposeOfferTx(
        offeree,
        offeree.address,
        10.0,
        [],
        [],
        {},
        offeree.address,
        "NFT receiver capability does not exists"
    )
}


pub fun testFailToProposeOfferBecauseAccountDoesNotHaveResolverCapability() {
    let offeree = accounts["offeree"]!
    // Setup NFTReceiver Capability.
    executeSetupExampleNFTAccount(offeree)
    // Execute proposeOffer transaction
    executeProposeOfferTx(
        offeree,
        offeree.address,
        10.0,
        [],
        [],
        {},
        offeree.address,
        "Resolver capability does not exists"
    )
}

pub fun testSetupResolver() {
    // Execute transaction
    executeSetupResolverTx(accounts["offeree"]!)
    // Verify the transaction effects by calling script
    assert(
        checkAccountHasOfferResolverPublicCapability(accounts["offeree"]!.address),
        message: "Given account doesn't hold the OpenOffers resoource"
    )
}

pub fun testFailToProposeOfferBecauseMaximumOfferAmountIsZero() {
    let offeree = accounts["offeree"]!
    // Execute proposeOffer transaction
    executeProposeOfferTx(
        offeree,
        offeree.address,
        0.0,
        [],
        [],
        {},
        offeree.address,
        "Offer amount can not be zero"
    )
}

// pub fun testFailToProposeOfferBecauseInsufficientBalance() {
//     let offeree = accounts["offeree"]!
//     // Execute proposeOffer transaction
//     executeProposeOfferTx(
//         offeree,
//         offeree.address,
//         1500.0,
//         [],
//         [], 
//         {"_type": "NFT", "typeId": "Type<@ExampleNFT.NFT>()"},
//         offeree.address,
//         "Insufficent balance in provided vault"
//     )
// }

pub fun testProposeOffer() {
    let offeree = accounts["offeree"]!
    let cutReceiver1 = accounts["cutReceiver1"]!
    let cutReceiver2 = accounts["cutReceiver2"]!

    // Setup the receiver of fungible token
    executeSetupVaultAndMintTokensTx(cutReceiver1, 0.0)
    executeSetupVaultAndMintTokensTx(cutReceiver2, 0.0)
    // Execute proposeOffer transaction
    executeProposeOfferTx(
        offeree,
        offeree.address,
        150.0,
        [cutReceiver1.address, cutReceiver2.address],
        [12.0, 13.0],
        {"resolver": "0", "nftId": "0"},
        offeree.address,
        nil
    )

    // Assertion
    let offerId = getOfferId(offeree.address, 0)
    let maximumOfferAmount = getOfferDetails(offeree.address, offerId)
    assert(getNoOfOfferCreated(offeree.address) == 1, message: "Incorrect creation of offer")
    assert(maximumOfferAmount == 150.0, message: "Incorrect Offer set")
}

pub fun testAcceptTheOffer() {
    let acceptor = accounts["offerAcceptor"]!
    let offeree = accounts["offeree"]!
    let royaltyReceiver1 = accounts["royaltyReceiver1"]!
    let royaltyReceiver2 = accounts["royaltyReceiver2"]!
    let cutReceiver1 = accounts["cutReceiver1"]!
    let cutReceiver2 = accounts["cutReceiver2"]!
    let minter = accounts["ExampleNFT"]!
    let offerId = getOfferId(offeree.address, 0)

    // Step 1: Setup the receiver of fungible token
    executeSetupVaultAndMintTokensTx(acceptor, 0.0)
    // Step 2: Setup the NFT collection for offer acceptor
    executeSetupExampleNFTAccount(acceptor)
    // Step 3: Mint the NFT and assign the royalties.
    // Step 3a: Setup royalties account
    executeSetupVaultAndSetupRoyaltyReceiver(royaltyReceiver1, /storage/exampleTokenVault)
    executeSetupVaultAndSetupRoyaltyReceiver(royaltyReceiver2, /storage/exampleTokenVault)
    // Step 3b: Mint NFT
    executeMintNFTTx(
        minter,
        acceptor.address,
        "BasketBall_1",
        "This is first basketball",
        "BASKETBALL",
        [0.1, 0.2],
        ["Artist", "Creator"],
        [royaltyReceiver1.address, royaltyReceiver2.address],
        nil
    )

    let expectedPaymentToOffree = getExpectedPaymentToOfferee(offerId, offeree.address, acceptor.address, 0, /public/exampleNFTCollection)

    assert(expectedPaymentToOffree == 87.5, message: "Incorrect balance send to acceptor \n Expected 87.5 but got - ".concat(expectedPaymentToOffree.toString()))

    // Execute accept transaction
    executeOfferAcceptTx(
        acceptor,
        0,
        offerId,
        offeree.address,
        nil
    )

    assert(getBalance(royaltyReceiver1.address) == 12.5, message: "Incorrect balance send to royalty receiver 1 \n Expected 12.5 but got - ".concat((getBalance(royaltyReceiver1.address)).toString()))
    assert(getBalance(royaltyReceiver2.address) == 25.0, message: "Incorrect balance send to royalty receiver 2 \n Expected 25.0 but got - ".concat((getBalance(royaltyReceiver2.address)).toString()))
    assert(getBalance(acceptor.address) == 87.5, message: "Incorrect balance send to acceptor \n Expected 87.5 but got - ".concat((getBalance(acceptor.address)).toString()))
    assert(getBalance(cutReceiver1.address) == 12.0, message: "Incorrect balance send to cut receiver 1 \n Expected 12.0 but got - ".concat((getBalance(cutReceiver1.address)).toString()))
    assert(getBalance(cutReceiver2.address) == 13.0, message: "Incorrect balance send to cut receiver 1 \n Expected 13.0 but got - ".concat((getBalance(cutReceiver2.address)).toString()))
    assert(getLatestCollectionId(offeree.address, /public/exampleNFTCollection) == 0, message: "Incorrect NFT get transferred")
}


///////////////////
/// Genric Helpers 
///////////////////

/// Helper function to deploy required smart contracts.
pub fun deploySmartContract(_ blockchain: Test.Blockchain, _ contractName: String, _ account: Test.Account, _ filePath: String) {
    let contractCode = Test.readFile(filePath)
    let err = blockchain.deployContract(
        name: contractName,
        code: contractCode,
        account: account,
        arguments: [],
    )
    if err != nil {
        panic(err!.message)
    }
}

pub fun txExecutor(_ txCode: String, _ signers: [Test.Account], _ arguments: [AnyStruct], _ expectedError: String?): Bool {
    let tx = Test.Transaction(
        code: txCode,
        authorizers: [signers[0].address],
        signers: signers,
        arguments: arguments,
    )
    let txResult = blockchain.executeTransaction(tx)
    if let err = txResult.error {
        if let expectedErrorMessage = expectedError {
            let panicErrMessage = err.message.slice(from: 73, upTo: 73 + expectedErrorMessage.length)
            let assertionErrMessage = err.message.slice(from: 84, upTo: 84 + expectedErrorMessage.length)
            let preConditionErrMessage = err.message.slice(from: 88, upTo: 88 + expectedErrorMessage.length)
            let hasEmittedCorrectMessage = panicErrMessage == expectedErrorMessage ? true : (assertionErrMessage == expectedErrorMessage ? true : preConditionErrMessage == expectedErrorMessage)
            let failureMessage = "Expecting - "
                .concat(expectedErrorMessage)
                .concat("\n")
                .concat("But received - ")
                .concat(err.message)
            assert(hasEmittedCorrectMessage, message: failureMessage)
            return true
        }
        panic(err.message)
    } else {
        if let expectedErrorMessage = expectedError {
            panic("Expecting error - ".concat(expectedErrorMessage).concat(". While no error triggered"))
        }
    }
    return txResult.status == Test.ResultStatus.succeeded
}


///////////////
/// Tx Helpers
///////////////

pub fun executeSetupAccountTx(_ signer: Test.Account) {
    let txCode = Test.readFile("../../../transactions/setup_account.cdc")
    assert(
        txExecutor(txCode, [signer], [], nil),
        message: "Failed to install OpenOffers resource in given offeree account"
    )
}

pub fun executeSetupResolverTx(_ signer: Test.Account) {
    let txCode = Test.readFile("../../../transactions/setup_resolver.cdc")
    assert(
        txExecutor(txCode, [signer], [], nil),
        message: "Failed to install OfferResolver resource in given offeree account"
    )
}

pub fun executeProposeOfferTx(
    _ signer: Test.Account,
    _ nftReceiver: Address,
    _ maximumOfferAmount: UFix64,
    _ cutReceivers: [Address],
    _ cuts: [UFix64],
    _ offerParamsString: {String: String},
    _ resolverRefProvider: Address,
    _ expectedError: String?
) {
    let txCode = Test.readFile("../../../transactions/propose_offer.cdc")
    assert(
        txExecutor(txCode, [signer], [nftReceiver, maximumOfferAmount, cutReceivers, cuts, offerParamsString, resolverRefProvider], expectedError),
        message: "Failed to propose offer"
    )
}

pub fun executeOfferAcceptTx(
    _ signer: Test.Account,
    _ nftId: UInt64,
    _ offerId: UInt64,
    _ openOffersHolder: Address,
    _ expectedError: String?
) {
    let txCode = Test.readFile("../../../transactions/accept_offer.cdc")
    assert(
        txExecutor(txCode, [signer], [nftId, offerId, openOffersHolder], expectedError),
        message: "Failed to accept offer"
    )
}

pub fun setupVault(_ whom: Test.Account) {
    let txCode = Test.readFile("./mocks/transactions/setup_example_token_account.cdc")
    assert(
        txExecutor(txCode, [whom], [], nil),
        message: "Failed to install Vault resource in given account"
    )
}

pub fun executeSetupVaultAndSetupRoyaltyReceiver(_ whom: Test.Account, _ vaultPath: StoragePath) {
    setupVault(whom)
    let txCode = Test.readFile("./mocks/transactions/setup_account_to_receive_royalty.cdc")
    assert(
        txExecutor(txCode, [whom], [vaultPath], nil),
        message: "Failed to setup account to receive royalty"
    )
}

pub fun mintTokens(_ recipient: Address, _ amount: UFix64) {
    let txCode = Test.readFile("./mocks/transactions/mint_tokens.cdc")
    assert(
        txExecutor(txCode, [accounts["ExampleToken"]!], [recipient, amount], nil),
        message: "Failed to mint tokens to given recipient"
    )
}

pub fun executeSetupVaultAndMintTokensTx(_ whom: Test.Account, _ amount: UFix64) {
    setupVault(whom)
    if amount != 0.0 {
        mintTokens(whom.address, amount)
        assert(getBalance(whom.address) == amount, message: "Balance mis-match")
    }
}

pub fun executeSetupExampleNFTAccount(_ whom: Test.Account) {
    let txCode = Test.readFile("./mocks/transactions/setup_example_nft_account.cdc")
    assert(
        txExecutor(txCode, [whom], [], nil),
        message: "Failed to setup account for ExampleNFT"
    )
}

pub fun executeMintNFTTx(
    _ signer: Test.Account,
    _ recipient: Address,
    _ name: String,
    _ description: String,
    _ thumbnail: String,
    _ cuts: [UFix64],
    _ royaltyDescriptions: [String],
    _ royaltyBeneficiaries: [Address],
    _ expectedError: String?
) {
    let txCode = Test.readFile("./mocks/transactions/mint_nft.cdc")
    assert(
        txExecutor(txCode, [signer], [recipient, name, description, thumbnail, cuts, royaltyDescriptions, royaltyBeneficiaries], expectedError),
        message: "Failed mint NFT for given receipient"
    )
}


///////////////////
/// Script Helpers
///////////////////

pub fun scriptExecutor(_ path: String, _ arguments: [AnyStruct]): AnyStruct? {
    let scriptCode = Test.readFile(path)
    let scriptResult = blockchain.executeScript(scriptCode, arguments)
    var failureMessage = ""
    if let failureError = scriptResult.error {
        failureMessage = "Failed to execute the script because -:  ".concat(failureError.message)
    }
    assert(scriptResult.status == Test.ResultStatus.succeeded, message: failureMessage)
    return scriptResult.returnValue
}

pub fun checkAccountHasOpenOffersPublicCapability(_ target: Address): Bool {
    let scriptResult = scriptExecutor("../../../scripts/check_open_offers_public_capability_exists.cdc", [target])
    return scriptResult! as! Bool
}


pub fun checkAccountHasOfferResolverPublicCapability(_ target: Address): Bool {
    let scriptResult = scriptExecutor("../../../scripts/check_offer_resolver_public_capability_exists.cdc", [target])
    return scriptResult! as! Bool
}

pub fun getTypeOfExampleNFT(): Type {
    let scriptResult = scriptExecutor("./mocks/scripts/get_type_of_example_nft.cdc", [])
    return scriptResult! as! Type
}

pub fun getBalance(_ target: Address): UFix64 {
    let scriptResult = scriptExecutor("./mocks/scripts/get_vault_balance.cdc", [target])
    return scriptResult! as! UFix64
}

pub fun getOfferCuts(_ receivers: [Address], _ amounts: [UFix64]): [AnyStruct] {
    let scriptResult = scriptExecutor("./mocks/scripts/get_offer_cuts.cdc", [receivers, amounts])
    return scriptResult! as! [AnyStruct]
}

pub fun getOfferId(_ account: Address, _ index: Int64): UInt64 {
    let scriptResult = scriptExecutor("./mocks/scripts/get_offer_ids_at_index.cdc", [account, index])
    return scriptResult! as! UInt64
}

pub fun getOfferIds(_ account: Address): [UInt64] {
    let scriptResult = scriptExecutor("../../../scripts/get_offer_ids.cdc", [account])
    return scriptResult! as! [UInt64]
}

pub fun getNoOfOfferCreated(_ account: Address): Int64 {
    let scriptResult = scriptExecutor("./mocks/scripts/get_offer_ids_length.cdc", [account])
    return scriptResult! as! Int64
}

pub fun getOfferDetails(_ target: Address, _ offerId: UInt64): UFix64 {
    let scriptResult = scriptExecutor("./mocks/scripts/get_offer_details.cdc", [target, offerId])
    return scriptResult! as! UFix64
}

pub fun getLatestCollectionId(_ address: Address, _ collectionPublicPath: PublicPath): UInt64 {
    var scriptResult = scriptExecutor("./mocks/scripts/get_collection_ids_length.cdc", [address, collectionPublicPath])
    let lengthOfCollectionId = scriptResult! as! Int64
    scriptResult = scriptExecutor("./mocks/scripts/get_collection_ids.cdc", [address, collectionPublicPath, lengthOfCollectionId - 1])
    return scriptResult! as! UInt64
}

pub fun getExpectedPaymentToOfferee(
    _ offerId: UInt64,
    _ offerCreator: Address,
    _ offereeAddress: Address,
    _ nftId: UInt64,
    _ collectionPublicPath: PublicPath
): UFix64 {
    let scriptResult = scriptExecutor("../../../scripts/get_expected_payment_to_offeree.cdc", [offerId, offerCreator, offereeAddress, nftId, collectionPublicPath])
    return scriptResult! as! UFix64
}