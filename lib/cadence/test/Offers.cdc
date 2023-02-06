import Test

pub var blockchain = Test.newEmulatorBlockchain()
pub var accounts: {String: Test.Account} = {}
pub enum ErrorType: UInt8 {
    pub case TX_PANIC
    pub case TX_ASSERT
    pub case TX_PRE
    pub case CONTRACT_WITHDRAWBALANCE
}

pub fun setup() {

    // Setup accounts for the smart contract.
    let offers = blockchain.createAccount()
    let offerMatcher = blockchain.createAccount()
    let exampleOfferMatcher = offerMatcher
    let nft = blockchain.createAccount()
    let metadataViews = blockchain.createAccount()
    let fungibleToken = blockchain.createAccount()
    let nonFungibleToken = blockchain.createAccount()
    let offeror = blockchain.createAccount()
    let token = blockchain.createAccount()
    let cutReceiver1 = blockchain.createAccount()
    let cutReceiver2 = blockchain.createAccount()
    let offerAcceptor = blockchain.createAccount()
    let royaltyReceiver1 = blockchain.createAccount()
    let royaltyReceiver2 = blockchain.createAccount()
    let commissionReceiver1 = blockchain.createAccount()
    let commissionReceiver2 = blockchain.createAccount()
    let paymentHandler = blockchain.createAccount()
    let fungibleTokenSwitchboard = blockchain.createAccount()
    let defaultPaymentHandler = blockchain.createAccount()
    let testToken = blockchain.createAccount()


    accounts = {
        "FungibleToken": fungibleToken,
        "NonFungibleToken": nonFungibleToken,
        "MetadataViews": metadataViews,
        "ExampleToken": token,
        "TestToken": testToken,
        "ExampleNFT": nft,
        "PaymentHandler": paymentHandler,
        "FungibleTokenSwitchboard": fungibleTokenSwitchboard,
        "DefaultPaymentHandler": defaultPaymentHandler,
        "OfferMatcher": offerMatcher,
        "ExampleOfferMatcher": offerMatcher,
        "Offers": offers,
        "offeror": offeror,
        "offerAcceptor": offerAcceptor,
        "royaltyReceiver1": royaltyReceiver1,
        "royaltyReceiver2": royaltyReceiver2,
        "cutReceiver1": cutReceiver1,
        "cutReceiver2": cutReceiver2,
        "CommissionReceiver1": commissionReceiver1,
        "CommissionReceiver2": commissionReceiver2
    }
    
    // Let the CLI know how the above addresses are mapped to the contracts.
    blockchain.useConfiguration(Test.Configuration({
        "./FungibleToken.cdc":accounts["FungibleToken"]!.address,
        "./NonFungibleToken.cdc":accounts["NonFungibleToken"]!.address,
        "./MetadataViews.cdc":accounts["MetadataViews"]!.address,
        "./PaymentHandler.cdc":accounts["PaymentHandler"]!.address,
        "./DefaultPaymentHandler.cdc":accounts["DefaultPaymentHandler"]!.address,
        "./core/FungibleToken.cdc":accounts["FungibleToken"]!.address,
        "./core/NonFungibleToken.cdc":accounts["NonFungibleToken"]!.address,
        "./core/MetadataViews.cdc":accounts["MetadataViews"]!.address,
        "./core/FungibleTokenSwitchboard.cdc":accounts["FungibleTokenSwitchboard"]!.address,
        "./OfferMatcher.cdc":accounts["OfferMatcher"]!.address,
        "../contracts/PaymentHandler.cdc":accounts["PaymentHandler"]!.address,
        "../contracts/TestToken.cdc":accounts["TestToken"]!.address,
        "../contracts/Offers.cdc": accounts["Offers"]!.address,
        "../contracts/OfferMatcher.cdc": accounts["OfferMatcher"]!.address,
        "../contracts/ExampleOfferMatcher.cdc": accounts["ExampleOfferMatcher"]!.address,
        "../contracts/core/FungibleToken.cdc": accounts["FungibleToken"]!.address,
        "../contracts/core/NonFungibleToken.cdc": accounts["NonFungibleToken"]!.address,
        "../contracts/core/ExampleToken.cdc": accounts["ExampleToken"]!.address,
        "../contracts/core/ExampleNFT.cdc": accounts["ExampleNFT"]!.address,
        "../contracts/core/MetadataViews.cdc": accounts["MetadataViews"]!.address,
        "../../../../../contracts/core/FungibleToken.cdc": accounts["FungibleToken"]!.address,
        "../../../../../contracts/core/ExampleToken.cdc": accounts["ExampleToken"]!.address,
        "../../../../../contracts/core/MetadataViews.cdc": accounts["MetadataViews"]!.address,
        "../../../../../contracts/core/NonFungibleToken.cdc": accounts["NonFungibleToken"]!.address,
        "../../../../../contracts/core/ExampleNFT.cdc": accounts["ExampleNFT"]!.address,
        "../../../../../contracts/core/FungibleTokenSwitchboard.cdc":accounts["FungibleTokenSwitchboard"]!.address,
        "../../../../../contracts/Offers.cdc": accounts["Offers"]!.address,
        "../../contracts/core/NonFungibleToken.cdc": accounts["NonFungibleToken"]!.address,
        "../../contracts/core/ExampleNFT.cdc": accounts["ExampleNFT"]!.address
    }))

    deploySmartContract("FungibleToken", accounts["FungibleToken"]!, "../../../contracts/core/FungibleToken.cdc")
    deploySmartContract("NonFungibleToken", accounts["NonFungibleToken"]!, "../../../contracts/core/NonFungibleToken.cdc")
    deploySmartContract("MetadataViews", accounts["MetadataViews"]!, "../../../contracts/core/MetadataViews.cdc")
    deploySmartContract("ExampleToken", accounts["ExampleToken"]!, "../../../contracts/core/ExampleToken.cdc")
    deploySmartContract("TestToken", accounts["TestToken"]!, "./mocks/contracts/TestToken.cdc")
    deploySmartContract("ExampleNFT", accounts["ExampleNFT"]!, "../../../contracts/core/ExampleNFT.cdc")
    deploySmartContract("FungibleTokenSwitchboard", accounts["FungibleTokenSwitchboard"]!, "../../../contracts/core/FungibleTokenSwitchboard.cdc")
    deploySmartContract("PaymentHandler", accounts["PaymentHandler"]!, "../../../contracts/PaymentHandler.cdc")
    deploySmartContract("DefaultPaymentHandler", accounts["DefaultPaymentHandler"]!, "../../../contracts/DefaultPaymentHandler.cdc")
    deploySmartContract("OfferMatcher", accounts["OfferMatcher"]!, "../../../contracts/OfferMatcher.cdc")
    deploySmartContract("ExampleOfferMatcher", accounts["ExampleOfferMatcher"]!, "../../../contracts/ExampleOfferMatcher.cdc")
    deploySmartContract("Offers", accounts["Offers"]!, "../../../contracts/Offers.cdc")
}

//////////////
/// Test Cases
//////////////


pub fun testCreateOpenOffers() {
    // Execute transaction
    executeSetupAccountTx(accounts["offeror"]!)
    // Verify the transaction effects by calling script
    assert(
        checkAccountHasOpenOffersPublicCapability(accounts["offeror"]!.address),
        message: "Given account doesn't hold the OpenOffers resoource"
    )
}

pub fun testFailToCreateOfferBecauseAccountDoesNotHaveOpenOffersResource() {
    let fakeOfferee = blockchain.createAccount()
    executeCreateOfferTx(
        fakeOfferee,
        fakeOfferee.address,
        10.0,
        [],
        [],
        {},
        fakeOfferee.address,
        2.0,
        nil,
        "Given account does not possess OpenOffers resource",
        ErrorType.TX_PANIC
    )
}

pub fun testFailToCreateOfferBecauseAccountDoesNotHaveNFTReceiverCapability() {
    let offeror = accounts["offeror"]!
    // Setup Token vault and top up with some tokens
    executeSetupVaultAndMintTokensTx(offeror, 1000.0)
    // Execute createOffer transaction
    executeCreateOfferTx(
        offeror,
        offeror.address,
        10.0,
        [],
        [],
        {},
        offeror.address,
        2.0,
        nil,
        "NFT receiver capability does not exists",
        ErrorType.TX_ASSERT
    )
}


pub fun testFailToCreateOfferBecauseAccountDoesNotHaveOfferMatcherCapability() {
    let offeror = accounts["offeror"]!
    // Setup NFTReceiver Capability.
    executeSetupExampleNFTAccount(offeror)
    // Execute createOffer transaction
    executeCreateOfferTx(
        offeror,
        offeror.address,
        10.0,
        [],
        [],
        {},
        offeror.address,
        2.0,
        nil,
        "OfferMatcher capability does not exists",
        ErrorType.TX_ASSERT
    )
}

pub fun testSetupOfferMatcher() {
    // Execute transaction
    executeSetupOfferMatcherTx(accounts["offeror"]!)
    // Verify the transaction effects by calling script
    assert(
        checkAccountHasOfferOfferMatcherPublicCapability(accounts["offeror"]!.address),
        message: "Given account doesn't hold the OpenOffers resoource"
    )
}

pub fun testFailToCreateOfferBecauseInsufficientOfferAmount() {
    let offeror = accounts["offeror"]!
    // Execute createOffer transaction
    executeCreateOfferTx(
        offeror,
        offeror.address,
        100.0,
        [],
        [], 
        {"_type": "NFT", "typeId": "Type<@ExampleNFT.NFT>()"},
        offeror.address,
        101.0,
        nil,
        "Insufficient offer amount",
        ErrorType.TX_ASSERT
    )
}

pub fun testFailToCreateOfferBecauseCommissionReceiverDoesNotHaveCapability() {
    let offeror = accounts["offeror"]!
    // Execute createOffer transaction
    executeCreateOfferTx(
        offeror,
        offeror.address,
        100.0,
        [],
        [], 
        {"_type": "NFT", "typeId": "Type<@ExampleNFT.NFT>()"},
        offeror.address,
        5.0,
        [accounts["CommissionReceiver1"]!.address],
        "Invalid capability of the commission receiver",
        ErrorType.TX_ASSERT
    )
}

pub fun testFailToCreateOfferBecauseInsufficientBalance() {
    let offeror = accounts["offeror"]!
    // Execute createOffer transaction
    executeCreateOfferTx(
        offeror,
        offeror.address,
        1500.0,
        [],
        [], 
        {"_type": "NFT", "typeId": "Type<@ExampleNFT.NFT>()"},
        offeror.address,
        2.0,
        nil,
        "Not sufficient withdrawableBalance",
        ErrorType.CONTRACT_WITHDRAWBALANCE
    )
}

pub fun testCreateOffer() {
    let offeror = accounts["offeror"]!
    let cutReceiver1 = accounts["cutReceiver1"]!
    let cutReceiver2 = accounts["cutReceiver2"]!
    let commissionReceiver1 = accounts["CommissionReceiver1"]!
    let commissionReceiver2 = accounts["CommissionReceiver2"]!

    // Setup the receiver of fungible token
    executeSetupVaultAndMintTokensTx(cutReceiver1, 0.0)
    executeSetupVaultAndMintTokensTx(cutReceiver2, 0.0)
    executeSetupVaultAndMintTokensTx(commissionReceiver1, 0.0)
    executeSetupVaultAndMintTokensTx(commissionReceiver2, 0.0)
    // Execute createOffer transaction
    executeCreateOfferTx(
        offeror,
        offeror.address,
        150.0,
        [cutReceiver1.address, cutReceiver2.address],
        [12.0, 13.0],
        {"matcher": UInt8(0), "nftId": UInt64(0)},
        offeror.address,
        5.0,
        [commissionReceiver1.address, commissionReceiver2.address],
        nil,
        nil
    )

    // Assertion
    let offerId = getOfferId(offeror.address, 0)
    let maximumOfferAmount = getOfferDetails(offeror.address, offerId)
    assert(getNoOfOfferCreated(offeror.address) == 1, message: "Incorrect creation of offer")
    assert(maximumOfferAmount == 150.0, message: "Incorrect Offer set")
}

pub fun testGetValidOfferFilterTypes() {
    let offeror = accounts["offeror"]!
    let offerId = getOfferId(offeror.address, 0)
    let validOfferFilterTypes = getValidOfferFilterTypes(offeror.address, offerId)
    assert(validOfferFilterTypes.length == 2, message: "Incorrect length")
}

pub fun testAcceptTheOffer() {
    let acceptor = accounts["offerAcceptor"]!
    let offeror = accounts["offeror"]!
    let royaltyReceiver1 = accounts["royaltyReceiver1"]!
    let royaltyReceiver2 = accounts["royaltyReceiver2"]!
    let cutReceiver1 = accounts["cutReceiver1"]!
    let cutReceiver2 = accounts["cutReceiver2"]!
    let minter = accounts["ExampleNFT"]!
    let offerId = getOfferId(offeror.address, 0)

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
        nil,
        nil
    )

    assert(isNFTCompatibleWithOffer(offerId, offeror.address, 0, acceptor.address), message: "NFT is not compabtible with offer filters")

    let expectedPaymentToOffree = calcNetPaymentToSeller(offerId, offeror.address, acceptor.address, 0, /public/exampleNFTCollection)

    assert(expectedPaymentToOffree == 76.5, message: "Incorrect balance send to acceptor \n Expected 76.5 but got - ".concat(expectedPaymentToOffree.toString()))
}

pub fun testProvidedNFTShouldNotBeCompatibleWithOffer() {
    let acceptor = accounts["offerAcceptor"]!
    let offeror = accounts["offeror"]!
    let minter = accounts["ExampleNFT"]!
    let royaltyReceiver1 = accounts["royaltyReceiver1"]!
    let royaltyReceiver2 = accounts["royaltyReceiver2"]!
    let offerId = getOfferId(offeror.address, 0)
    
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
        nil,
        nil
    )

    assert(!isNFTCompatibleWithOffer(offerId, offeror.address, 1, acceptor.address), message: "NFT should not compabtible with offer filters")
}

pub fun testFailToAcceptOfferBecauseOpenOffersResourceDoesNotExists() {
    let acceptor = accounts["offerAcceptor"]!
    let offeror = accounts["offeror"]!
    let commissionReceiver = accounts["CommissionReceiver1"]!
    let offerId = getOfferId(offeror.address, 0)
    let fakeAccount = blockchain.createAccount()
    
    // It should fail because of OpenOffer doesn't exists
    executeOfferAcceptTx(
        acceptor,
        0,
        offerId,
        fakeAccount.address,
        commissionReceiver.address,
        "Could not borrow OpenOffers from provided address",
        ErrorType.TX_PANIC
    )
}

pub fun testFailToAcceptOfferBecauseReceiverCapabilityIsInvalid() {
    let offeror = accounts["offeror"]!
    let commissionReceiver = accounts["CommissionReceiver1"]!
    let offerId = getOfferId(offeror.address, 0)
    let fakeReceiver = blockchain.createAccount()
    
    // It should fail because of OpenOffer doesn't exists
    executeOfferAcceptTx(
        fakeReceiver,
        0,
        offerId,
        offeror.address,
        commissionReceiver.address,
        "Missing or mis-typed given vault receiver",
        ErrorType.TX_ASSERT
    )
}

pub fun testFailToAcceptOfferBecauseCommissionReceiverCapabilityIsInvalid() {
    let acceptor = accounts["offerAcceptor"]!
    let offeror = accounts["offeror"]!
    let commissionReceiver = accounts["CommissionReceiver1"]!
    let offerId = getOfferId(offeror.address, 0)
    let fakeCommissionReceiver = blockchain.createAccount()
    
    // It should fail because of OpenOffer doesn't exists
    executeOfferAcceptTx(
        acceptor,
        0,
        offerId,
        offeror.address,
        fakeCommissionReceiver.address,
        "Missing or mis-typed given commission receiver vault",
        ErrorType.TX_ASSERT
    )
}

pub fun testAcceptOfferAndCleanup() {
    let acceptor = accounts["offerAcceptor"]!
    let offeror = accounts["offeror"]!
    let royaltyReceiver1 = accounts["royaltyReceiver1"]!
    let royaltyReceiver2 = accounts["royaltyReceiver2"]!
    let cutReceiver1 = accounts["cutReceiver1"]!
    let cutReceiver2 = accounts["cutReceiver2"]!
    let minter = accounts["ExampleNFT"]!
    let commissionReceiver1 = accounts["CommissionReceiver1"]!
    let offerId = getOfferId(offeror.address, 0)

    // Execute accept transaction
    executeOfferAcceptTx(
        acceptor,
        0,
        offerId,
        offeror.address,
        commissionReceiver1.address,
        nil,
        nil
    )

    assert(
        getBalance(royaltyReceiver1.address) == 14.5,
        message: "Incorrect balance send to royalty receiver 1 \n Expected 12.5 but got - ".concat((getBalance(royaltyReceiver1.address)).toString())
    )
    assert(
        getBalance(royaltyReceiver2.address) == 29.0,
        message: "Incorrect balance send to royalty receiver 2 \n Expected 25.0 but got - ".concat((getBalance(royaltyReceiver2.address)).toString())
    )
    assert(
        getBalance(acceptor.address) == 76.5,
        message: "Incorrect balance send to acceptor \n Expected 87.5 but got - ".concat((getBalance(acceptor.address)).toString())
    )
    assert(
        getBalance(cutReceiver1.address) == 12.0,
        message: "Incorrect balance send to cut receiver 1 \n Expected 12.0 but got - ".concat((getBalance(cutReceiver1.address)).toString())
    )
    assert(
        getBalance(cutReceiver2.address) == 13.0,
        message: "Incorrect balance send to cut receiver 1 \n Expected 13.0 but got - ".concat((getBalance(cutReceiver2.address)).toString())
    )
    assert(
        getBalance(commissionReceiver1.address) == 5.0,
        message: "Incorrect balance send to commission receiver 1 \n Expected 5.0 but got - ".concat((getBalance(commissionReceiver1.address)).toString())
    )
    assert(
        getLatestCollectionId(offeror.address, /public/exampleNFTCollection) == 0,
        message: "Incorrect NFT get transferred"
    )
}

pub fun testGhostListingScenario() {
    let acceptor = accounts["offerAcceptor"]!
    let offeror = accounts["offeror"]!
    let royaltyReceiver1 = accounts["royaltyReceiver1"]!
    let royaltyReceiver2 = accounts["royaltyReceiver2"]!
    let cutReceiver1 = accounts["cutReceiver1"]!
    let cutReceiver2 = accounts["cutReceiver2"]!
    let minter = accounts["ExampleNFT"]!
    let commissionReceiver1 = accounts["CommissionReceiver1"]!
    let unknownReceiver = blockchain.createAccount()

    // Execute createOffer transaction
    executeCreateOfferTx(
        offeror,
        offeror.address,
        150.0,
        [cutReceiver1.address, cutReceiver2.address],
        [12.0, 13.0],
        {"matcher": UInt8(0), "nftId": UInt64(2)},
        offeror.address,
        5.0,
        [commissionReceiver1.address],
        nil,
        nil
    )

    // Assertion
    let offerId = getOfferId(offeror.address, 0)
    let maximumOfferAmount = getOfferDetails(offeror.address, offerId)
    assert(getNoOfOfferCreated(offeror.address) == 1, message: "Incorrect creation of offer")
    assert(maximumOfferAmount == 150.0, message: "Incorrect Offer set")

    // Step 1: Setup the receiver of fungible token
    executeSetupVaultAndMintTokensTx(unknownReceiver, 0.0)
    // Move the funds from provider vault
    executeTransferFundsFromPrivateCapability(offeror, unknownReceiver.address, 150.0)
   
    assert(
        getBalance(unknownReceiver.address) == 150.0,
        message: "Incorrect balance send to unknownReceiver receiver  \n Expected 150.0 but got - ".concat((getBalance(unknownReceiver.address)).toString())
    )

    // Cleanup the ghost offer
    executeCleanupGhostOffersTx(unknownReceiver, offerId, offeror.address)
}

pub fun testPaymentAccurementWhenCapabilityTypeDiffersAndCommissionIsGrabForAnyone() {
    let acceptor = accounts["offerAcceptor"]!
    let offeror = accounts["offeror"]!
    let royaltyRecv1 = blockchain.createAccount()
    let royaltyRecv2 = blockchain.createAccount()
    let cutReceiver1 = accounts["cutReceiver1"]!
    let cutReceiver2 = accounts["cutReceiver2"]!
    let minter = accounts["ExampleNFT"]!
    let commissionReceiver1 = accounts["CommissionReceiver1"]!
    let unknownReceiver = blockchain.createAccount()

    // Execute createOffer transaction
    executeCreateOfferTx(
        offeror,
        offeror.address,
        150.0,
        [cutReceiver1.address, cutReceiver2.address],
        [12.0, 13.0],
        {"matcher": UInt8(0), "nftId": UInt64(2)},
        offeror.address,
        5.0,
        [],
        nil,
        nil
    )

    // Assertion
    let offerId = getOfferId(offeror.address, 0)
    let maximumOfferAmount = getOfferDetails(offeror.address, offerId)
    assert(getNoOfOfferCreated(offeror.address) == 1, message: "Incorrect creation of offer")
    assert(maximumOfferAmount == 150.0, message: "Incorrect Offer set")


    // Setup Royalties receiver
    //
    // 1. RoyaltyRecv1 would use FungibleTokenSwitchboard and correct token vault to receive funds
    // 1.a Setup vault for ExampleToken
    setupVault(royaltyRecv1, 1) // 1 for ExampleToken
    // 1.b Use FungibleTokenSwitchboard to receive funds
    executeSetupSwitchboardToReceiveRoyaltyTx(royaltyRecv1, /storage/exampleTokenVault, /public/exampleTokenReceiver)

    // 2. royaltyRecv2 would use FungibleTokenSwitchboard and incorrect token vault to receive funds
    // 2.a Setup vault for TestToken
    setupVault(royaltyRecv2, 2) // 2 for TestToken
    // 2.b Use FungibleTokenSwitchboard to receive funds
    executeSetupSwitchboardToReceiveRoyaltyTx(royaltyRecv2, /storage/testTokenVault, /public/testTokenReceiver)

    // Step 3.a: Mint NFT
    executeMintNFTTx(
        minter,
        acceptor.address,
        "BasketBall_4",
        "This is first basketball",
        "BASKETBALL",
        [0.1, 0.2],
        ["Artist", "Creator"],
        [royaltyRecv1.address, royaltyRecv2.address],
        nil,
        nil
    )

    assert(isNFTCompatibleWithOffer(offerId, offeror.address, 2, acceptor.address), message: "NFT should not compabtible with offer filters")

    // Execute accept transaction
    executeOfferAcceptTx(
        acceptor,
        2,
        offerId,
        offeror.address,
        commissionReceiver1.address,
        nil,
        nil
    )

    assert(checkReceiverCapabilityConformPaymentHandler(royaltyRecv1.address, /public/GenericFTReceiver, accounts["Offers"]!.address), message: "Should be true")

    assert(
        getBalance(royaltyRecv1.address) == 14.5,
        message: "Incorrect balance send to royalty receiver 1 \n Expected 14.5 but got - ".concat((getBalance(royaltyRecv1.address)).toString())
    )
    // royaltyRecv2 wouldn't get any funds and funds allocated to it transferred to acceptor i.e. 29.0
    assert(
        getBalance(acceptor.address) == 76.5 + 29.0 + 76.5,  // 76.5 would be its existing balance
        message: "Incorrect balance send to acceptor \n Expected 182.0 but got - ".concat((getBalance(acceptor.address)).toString())
    )
    assert(
        getBalance(cutReceiver1.address) == 12.0 + 12.0, // 12.0 would be its existing balance
        message: "Incorrect balance send to cut receiver 1 \n Expected 24.0 but got - ".concat((getBalance(cutReceiver1.address)).toString())
    )
    assert(
        getBalance(cutReceiver2.address) == 13.0 + 13.0, // 13.0 would be its existing balance
        message: "Incorrect balance send to cut receiver 1 \n Expected 26.0 but got - ".concat((getBalance(cutReceiver2.address)).toString())
    )
    assert(
        getBalance(commissionReceiver1.address) == 5.0 + 5.0, // 10.0 would be its existing balance
        message: "Incorrect balance send to commission receiver 1 \n Expected 10.0 but got - ".concat((getBalance(commissionReceiver1.address)).toString())
    )
    assert(
        getLatestCollectionId(offeror.address, /public/exampleNFTCollection) == 0,
        message: "Incorrect NFT get transferred"
    )
}


///////////////////
/// Genric Helpers 
///////////////////

/// Helper function to deploy required smart contracts.
pub fun deploySmartContract(_ contractName: String, _ account: Test.Account, _ filePath: String) {
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

pub fun getErrorMessagePointer(errorType: ErrorType) : Int {
    switch errorType {
        case ErrorType.TX_PANIC: return 159
        case ErrorType.TX_ASSERT: return 170
        case ErrorType.TX_PRE: return 174
        case ErrorType.CONTRACT_WITHDRAWBALANCE: return 679
        default: panic("Invalid error type")
    }
    return 0
}

pub fun txExecutor(_ txCode: String, _ signers: [Test.Account], _ arguments: [AnyStruct], _ expectedError: String?, _ expectedErrorType: ErrorType?): Bool {
    let tx = Test.Transaction(
        code: txCode,
        authorizers: [signers[0].address],
        signers: signers,
        arguments: arguments,
    )
    let txResult = blockchain.executeTransaction(tx)
    if let err = txResult.error {
        if let expectedErrorMessage = expectedError {
            let ptr = getErrorMessagePointer(errorType: expectedErrorType!)
            let errMessage = err.message.slice(from: ptr, upTo: ptr + expectedErrorMessage.length)
            let hasEmittedCorrectMessage = errMessage == expectedErrorMessage ? true : false
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
        txExecutor(txCode, [signer], [], nil, nil),
        message: "Failed to install OpenOffers resource in given offeror account"
    )
}

pub fun executeSetupOfferMatcherTx(_ signer: Test.Account) {
    let txCode = Test.readFile("../../../transactions/setup_offer_matcher.cdc")
    assert(
        txExecutor(txCode, [signer], [], nil, nil),
        message: "Failed to install OfferMatcher resource in given offeror account"
    )
}

pub fun executeCreateOfferTx(
    _ signer: Test.Account,
    _ nftReceiver: Address,
    _ maximumOfferAmount: UFix64,
    _ cutReceivers: [Address],
    _ cuts: [UFix64],
    _ offerFilters: {String: AnyStruct},
    _ matcherRefProvider: Address,
    _ commissionAmount: UFix64,
    _ commissionReceivers: [Address]?,
    _ expectedError: String?,
    _ expectedErrorType: ErrorType?
) {
    let txCode = Test.readFile("../../../transactions/propose_offer.cdc")
    assert(
        txExecutor(txCode, [signer], [nftReceiver, maximumOfferAmount, cutReceivers, cuts, offerFilters, matcherRefProvider, commissionAmount, commissionReceivers], expectedError, expectedErrorType),
        message: "Failed to propose offer"
    )
}

pub fun executeOfferAcceptTx(
    _ signer: Test.Account,
    _ nftId: UInt64,
    _ offerId: UInt64,
    _ openOffersHolder: Address,
    _ commissionReceiver: Address,
    _ expectedError: String?,
    _ expectedErrorType: ErrorType?
) {
    let txCode = Test.readFile("../../../transactions/accept_offer_and_cleanup.cdc")
    assert(
        txExecutor(txCode, [signer], [nftId, offerId, openOffersHolder, commissionReceiver], expectedError, expectedErrorType),
        message: "Failed to accept offer"
    )
}

pub fun setupVault(_ whom: Test.Account, _ tokenType: UInt8) {
    let txCode = Test.readFile("./mocks/transactions/setup_example_token_account.cdc")
    assert(
        txExecutor(txCode, [whom], [tokenType], nil, nil),
        message: "Failed to install Vault resource in given account"
    )
}

pub fun executeSetupVaultAndSetupRoyaltyReceiver(_ whom: Test.Account, _ vaultPath: StoragePath) {
    setupVault(whom, 1)
    let txCode = Test.readFile("./mocks/transactions/setup_account_to_receive_royalty.cdc")
    assert(
        txExecutor(txCode, [whom], [vaultPath], nil, nil),
        message: "Failed to setup account to receive royalty"
    )
}

pub fun executeSetupVaultForTestTokenAndSetupRoyaltyReceiver(_ whom: Test.Account, _ vaultPath: StoragePath) {
    setupVault(whom, 2)
    let txCode = Test.readFile("./mocks/transactions/setup_account_to_receive_royalty.cdc")
    assert(
        txExecutor(txCode, [whom], [vaultPath], nil, nil),
        message: "Failed to setup account to receive royalty"
    )
}

pub fun mintTokens(_ recipient: Address, _ amount: UFix64) {
    let txCode = Test.readFile("./mocks/transactions/mint_tokens.cdc")
    assert(
        txExecutor(txCode, [accounts["ExampleToken"]!], [recipient, amount], nil, nil),
        message: "Failed to mint tokens to given recipient"
    )
}

pub fun executeSetupVaultAndMintTokensTx(_ whom: Test.Account, _ amount: UFix64) {
    setupVault(whom, 1)
    if amount != 0.0 {
        mintTokens(whom.address, amount)
        assert(getBalance(whom.address) == amount, message: "Balance mis-match")
    }
}

pub fun executeSetupExampleNFTAccount(_ whom: Test.Account) {
    let txCode = Test.readFile("./mocks/transactions/setup_example_nft_account.cdc")
    assert(
        txExecutor(txCode, [whom], [], nil, nil),
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
    _ expectedError: String?,
    _ expectedErrorType: ErrorType?
) {
    let txCode = Test.readFile("./mocks/transactions/mint_nft.cdc")
    assert(
        txExecutor(txCode, [signer], [recipient, name, description, thumbnail, cuts, royaltyDescriptions, royaltyBeneficiaries], expectedError, expectedErrorType),
        message: "Failed mint NFT for given receipient"
    )
}

pub fun executeTransferFundsFromPrivateCapability(
    _ from: Test.Account,
    _ to: Address,
    _ value: UFix64
) {
    let txCode = Test.readFile("./mocks/transactions/transfer_funds_using_private_capability.cdc")
    assert(
        txExecutor(txCode, [from], [value, to], nil, nil),
        message: "Failed to transfer tokens"
    )
}

pub fun executeCleanupGhostOffersTx(
    _ signer: Test.Account,
    _ offerId: UInt64,
    _ openOfferOwner: Address
) {
    let txCode = Test.readFile("../../../transactions/cleanup_ghost_offer.cdc")
    assert(
        txExecutor(txCode, [signer], [offerId, openOfferOwner], nil, nil),
        message: "Failed to cleanup the ghost offer"
    )
}

pub fun executeSetupSwitchboardToReceiveRoyaltyTx(
    _ signer: Test.Account,
    _ vaultPath: StoragePath,
    _ receiverPath: PublicPath
) {
    let txCode = Test.readFile("./mocks/transactions/setup_switchboard_to_account_to_receive_royalty.cdc")
    assert(
        txExecutor(txCode, [signer], [vaultPath, receiverPath], nil, nil),
        message: "Failed to cleanup the ghost offer"
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

pub fun checkReceiverCapabilityConformPaymentHandler(
    _ receiver: Address,
    _ receiverPath: PublicPath,
    _ defaultPaymentHandlerOwner: Address
): Bool {
    let scriptResult = scriptExecutor("../../../scripts/check_receiver_capability_conforms_payment_handler.cdc", [receiver, receiverPath, defaultPaymentHandlerOwner])
    return scriptResult! as! Bool
}

pub fun checkAccountHasOpenOffersPublicCapability(_ target: Address): Bool {
    let scriptResult = scriptExecutor("../../../scripts/check_open_offers_public_capability_exists.cdc", [target])
    return scriptResult! as! Bool
}


pub fun checkAccountHasOfferOfferMatcherPublicCapability(_ target: Address): Bool {
    let scriptResult = scriptExecutor("../../../scripts/check_offer_matcher_public_capability_exists.cdc", [target])
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
    assert(lengthOfCollectionId > 0, message: "There is no NFT present in the collection")
    scriptResult = scriptExecutor("./mocks/scripts/get_collection_ids.cdc", [address, collectionPublicPath, lengthOfCollectionId - 1])
    return scriptResult! as! UInt64
}

pub fun isCollectionEmpty(_ address: Address, _ collectionPublicPath: PublicPath): Bool {
    var scriptResult = scriptExecutor("./mocks/scripts/get_collection_ids_length.cdc", [address, collectionPublicPath])
    let lengthOfCollectionId = scriptResult! as! Int64
    return lengthOfCollectionId == 0
}

pub fun calcNetPaymentToSeller(
    _ offerId: UInt64,
    _ offerCreator: Address,
    _ offereeAddress: Address,
    _ nftId: UInt64,
    _ collectionPublicPath: PublicPath
): UFix64 {
    let scriptResult = scriptExecutor("../../../scripts/calc_net_payment_to_seller.cdc", [offerId, offerCreator, offereeAddress, nftId, collectionPublicPath])
    return scriptResult! as! UFix64
}

pub fun getValidOfferFilterTypes(_ account: Address, _ offerId: UInt64): {String: String} {
    let scriptResult = scriptExecutor("../../../scripts/get_valid_offer_filter_types.cdc", [account, offerId])
    return scriptResult! as! {String: String}
}

pub fun getCollectionIdsAtIndex(_ account: Address, _ collectionPath: PublicPath, _ index: Int64): UInt64 {
    let scriptResult = scriptExecutor("./mocks/scripts/get_collection_ids.cdc", [account, collectionPath, index])
    return scriptResult! as! UInt64
}

pub fun getCollectionIdsLength(_ account: Address, _ collectionPath: PublicPath): Int64 {
    let scriptResult = scriptExecutor("./mocks/scripts/get_collection_ids_length.cdc", [account, collectionPath])
    return scriptResult! as! Int64
}

pub fun isNFTCompatibleWithOffer(
    _ offerId: UInt64,
    _ offerCreator: Address,
    _ nftId: UInt64,
    _ nftAccountOwner: Address
): Bool {
    let scriptResult = scriptExecutor("../../../scripts/check_offer_matches_with_nft.cdc", [offerId, offerCreator, nftId, nftAccountOwner])
    return scriptResult! as! Bool
}