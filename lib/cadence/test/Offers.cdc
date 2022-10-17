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

    accounts = {
        "FungibleToken": fungibleToken,
        "NonFungibleToken": nonFungibleToken,
        "MetadataViews": metadataViews,
        "ExampleToken": token,
        "ExampleNFT": nft,
        "Resolver": resolver,
        "ExampleOfferResolver": resolver,
        "Offers": offers,
        "offeree": offeree
    }


    deploySmartContract(blockchain, "FungibleToken", accounts["FungibleToken"]!, "../../../contracts/utility/FungibleToken.cdc")
    deploySmartContract(blockchain, "NonFungibleToken", accounts["NonFungibleToken"]!, "../../../contracts/utility/NonFungibleToken.cdc")

    // Let the CLI know how the above addresses are mapped to the contracts.
    blockchain.useConfiguration(Test.Configuration({
        "./FungibleToken.cdc":accounts["FungibleToken"]!.address,
        "./NonFungibleToken.cdc":accounts["NonFungibleToken"]!.address
    }))

    deploySmartContract(blockchain, "MetadataViews", accounts["MetadataViews"]!, "../../../contracts/utility/MetadataViews.cdc")
    deploySmartContract(blockchain, "ExampleToken", accounts["ExampleToken"]!, "../../../contracts/utility/ExampleToken.cdc")

    // Let the CLI know how the above addresses are mapped to the contracts.
    blockchain.useConfiguration(Test.Configuration({
        "./FungibleToken.cdc":accounts["FungibleToken"]!.address,
        "./NonFungibleToken.cdc":accounts["NonFungibleToken"]!.address,
        "./MetadataViews.cdc":accounts["MetadataViews"]!.address
    }))

    deploySmartContract(blockchain, "ExampleNFT", accounts["ExampleNFT"]!, "../../../contracts/utility/ExampleNFT.cdc")

    // Let the CLI know how the above addresses are mapped to the contracts.
    blockchain.useConfiguration(Test.Configuration({
        "./utility/FungibleToken.cdc":accounts["FungibleToken"]!.address,
        "./utility/NonFungibleToken.cdc":accounts["NonFungibleToken"]!.address,
        "./utility/MetadataViews.cdc":accounts["MetadataViews"]!.address
    }))

    deploySmartContract(blockchain, "Resolver", accounts["Resolver"]!, "../../../contracts/Resolver.cdc")

    // Let the CLI know how the above addresses are mapped to the contracts.
    blockchain.useConfiguration(Test.Configuration({
        "./utility/FungibleToken.cdc":accounts["FungibleToken"]!.address,
        "./utility/NonFungibleToken.cdc":accounts["NonFungibleToken"]!.address,
        "./utility/MetadataViews.cdc":accounts["MetadataViews"]!.address,
        "./Resolver.cdc":accounts["Resolver"]!.address
    }))

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
        {},
        offeree.address,
        "Offer amount can not be zero"
    )
}

// pub fun testFailToProposeOfferBecauseInsufficientBalance() {
//     let offeree = accounts["offeree"]!
//     // Create fungible token vaults for cuts receiver
//     // let cutBeneficiary1 = (blockchain.createAccount()).address
//     // let cutBeneficiary2 = (blockchain.createAccount()).address
//     // let cuts = getOfferCuts([cutBeneficiary1, cutBeneficiary2], [10.0, 20.0])
//     // Execute proposeOffer transaction
//     executeProposeOfferTx(
//         offeree,
//         offeree.address,
//         1500.0,
//         // Did not add cuts because of incompetent cadence test framwork
//         [],
//         {"_type": "NFT", "typeId": "Type<@ExampleNFT.NFT>()"},
//         offeree.address,
//         "Insufficent balance in provided vault"
//     )
// }

pub fun testProposeOffer() {
    let offeree = accounts["offeree"]!
    // Execute proposeOffer transaction
    executeProposeOfferTx(
        offeree,
        offeree.address,
        150.0,
        // Did not add cuts because of incompetent cadence test framwork
        [],
        {"_type": "NFT", "typeId": "Type<@ExampleNFT.NFT>()"},
        offeree.address,
        nil
    )

    // Assertion
    let offerId = getOfferId(offeree.address, 0)
    //let offerDetails = getOfferDetails(offeree.address, offerId)
    assert(getNoOfOfferCreated(offeree.address) == 1, message: "Incorrect creation of offer")
    //assert(offerDetails.maximumOfferAmount == 150.0, message: "Incorrect Offer set")
}

pub fun testFailToGetArrayFromScript() {
    let offeree = accounts["offeree"]!
    getOfferIds(offeree.address)
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
            let endMessage = err.message.slice(from: err.message.length - expectedErrorMessage.length, upTo: err.message.length)
            let hasEmittedCorrectMessage = panicErrMessage == expectedErrorMessage ? true : (assertionErrMessage == expectedErrorMessage ? true : preConditionErrMessage == expectedErrorMessage)
            let failureMessage = "Expecting - "
                .concat(expectedErrorMessage)
                .concat("\n")
                .concat("But received - ")
                .concat(err.message)
            assert(hasEmittedCorrectMessage, message: endMessage)
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
    blockchain.useConfiguration(Test.Configuration({
        "../contracts/Offers.cdc": accounts["Offers"]!.address
    }))
    let txCode = Test.readFile("../../../transactions/setup_account.cdc")
    assert(
        txExecutor(txCode, [signer], [], nil),
        message: "Failed to install OpenOffers resource in given offeree account"
    )
}

pub fun executeSetupResolverTx(_ signer: Test.Account) {
    blockchain.useConfiguration(Test.Configuration({
        "../contracts/Resolver.cdc": accounts["Resolver"]!.address,
        "../contracts/ExampleOfferResolver.cdc": accounts["ExampleOfferResolver"]!.address
    }))
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
    _ offerCuts: [AnyStruct],
    _ offerParamsString: {String: String},
    _ resolverRefProvider: Address,
    _ expectedError: String?
) {
    blockchain.useConfiguration(Test.Configuration({
        "../contracts/Resolver.cdc": accounts["Resolver"]!.address,
        "../contracts/Offers.cdc": accounts["Offers"]!.address,
        "../contracts/utility/FungibleToken.cdc": accounts["FungibleToken"]!.address,
        "../contracts/utility/NonFungibleToken.cdc": accounts["NonFungibleToken"]!.address,
        "../contracts/utility/ExampleToken.cdc": accounts["ExampleToken"]!.address,
        "../contracts/utility/ExampleNFT.cdc": accounts["ExampleNFT"]!.address
    }))
    let txCode = Test.readFile("../../../transactions/propose_offer_for_example_nft.cdc")
    assert(
        txExecutor(txCode, [signer], [nftReceiver, maximumOfferAmount, offerCuts, offerParamsString, resolverRefProvider], expectedError),
        message: "Failed to propose offer"
    )
}

pub fun setupVault(_ whom: Test.Account) {
    blockchain.useConfiguration(Test.Configuration({
        "../../../../../contracts/utility/FungibleToken.cdc": accounts["FungibleToken"]!.address,
        "../../../../../contracts/utility/ExampleToken.cdc": accounts["ExampleToken"]!.address
    }))
    let txCode = Test.readFile("./mocks/transactions/setup_example_token_account.cdc")
    assert(
        txExecutor(txCode, [whom], [], nil),
        message: "Failed to install Vault resource in given account"
    )
}

pub fun mintTokens(_ recipient: Address, _ amount: UFix64) {
    blockchain.useConfiguration(Test.Configuration({
        "../../../../../contracts/utility/FungibleToken.cdc": accounts["FungibleToken"]!.address,
        "../../../../../contracts/utility/ExampleToken.cdc": accounts["ExampleToken"]!.address
    }))
    let txCode = Test.readFile("./mocks/transactions/mint_tokens.cdc")
    assert(
        txExecutor(txCode, [accounts["ExampleToken"]!], [recipient, amount], nil),
        message: "Failed to mint tokens to given recipient"
    )
}

pub fun executeSetupVaultAndMintTokensTx(_ whom: Test.Account, _ amount: UFix64) {
    setupVault(whom)
    mintTokens(whom.address, amount)
    assert(getBalance(whom.address) == amount, message: "Balance mis-match")
}

pub fun executeSetupExampleNFTAccount(_ whom: Test.Account) {
     blockchain.useConfiguration(Test.Configuration({
        "../../../../../contracts/utility/NonFungibleToken.cdc": accounts["NonFungibleToken"]!.address,
        "../../../../../contracts/utility/ExampleNFT.cdc": accounts["ExampleNFT"]!.address,
        "../../../../../contracts/utility/MetadataViews.cdc": accounts["MetadataViews"]!.address
    }))

    let txCode = Test.readFile("./mocks/transactions/setup_example_nft_account.cdc")
    assert(
        txExecutor(txCode, [whom], [], nil),
        message: "Failed to setup account for ExampleNFT"
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
    blockchain.useConfiguration(Test.Configuration({
        "../../../../../contracts/utility/ExampleNFT.cdc": accounts["ExampleNFT"]!.address
    }))
    let scriptResult = scriptExecutor("./mocks/scripts/get_type_of_example_nft.cdc", [])
    return scriptResult! as! Type
}

pub fun getBalance(_ target: Address): UFix64 {
    blockchain.useConfiguration(Test.Configuration({
        "../../../../../contracts/utility/FungibleToken.cdc": accounts["FungibleToken"]!.address,
        "../../../../../contracts/utility/ExampleToken.cdc": accounts["ExampleToken"]!.address
    }))
    let scriptResult = scriptExecutor("./mocks/scripts/get_vault_balance.cdc", [target])
    return scriptResult! as! UFix64
}

pub fun getOfferCuts(_ receivers: [Address], _ amounts: [UFix64]): [AnyStruct] {
    blockchain.useConfiguration(Test.Configuration({
        "../../../../../contracts/Offers.cdc": accounts["Offers"]!.address,
        "../../../../../contracts/utility/FungibleToken.cdc": accounts["FungibleToken"]!.address,
        "../../../../../contracts/utility/ExampleToken.cdc": accounts["ExampleToken"]!.address
    }))
    let scriptResult = scriptExecutor("./mocks/scripts/get_offer_cuts.cdc", [receivers, amounts])
    return scriptResult! as! [AnyStruct]
}

pub fun getOfferId(_ account: Address, _ index: Int64): UInt64 {
    blockchain.useConfiguration(Test.Configuration({
        "../../../../../contracts/Offers.cdc": accounts["Offers"]!.address
    }))
    let scriptResult = scriptExecutor("./mocks/scripts/get_offer_ids_at_index.cdc", [account, index])
    return scriptResult! as! UInt64
}

pub fun getOfferIds(_ account: Address): [UInt64] {
    blockchain.useConfiguration(Test.Configuration({
        "../contracts/Offers.cdc": accounts["Offers"]!.address
    }))
    let scriptResult = scriptExecutor("../../../scripts/get_offer_ids.cdc", [account])
    return scriptResult! as! [UInt64]
}

pub fun getNoOfOfferCreated(_ account: Address): Int64 {
    blockchain.useConfiguration(Test.Configuration({
        "../../../../../contracts/Offers.cdc": accounts["Offers"]!.address
    }))
    let scriptResult = scriptExecutor("./mocks/scripts/get_offer_ids_length.cdc", [account])
    return scriptResult! as! Int64
}

// pub fun getOfferDetails(_ target: Address, _ offerId: UInt64): (UInt64, Type) {
//     blockchain.useConfiguration(Test.Configuration({
//         "../contracts/Offers.cdc": accounts["Offers"]!.address
//     }))
//     let scriptResult = scriptExecutor("./mocks/scripts/get_offer_details.cdc", [target, offerId])
//     return scriptResult! as! (UInt64, Type)
// }


