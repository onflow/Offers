import Test
//import Offers from "./Offers.cdc"

pub var blockchain = Test.newEmulatorBlockchain()
pub var accounts: {String: Test.Account} = {}

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

    let accounts: {String: Test.Account} = {
        "FungibleToken": fungibleToken,
        "NonFungibleToken": nonFungibleToken,
        "MetadataViews": metadataViews,
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

/// Utility function to deploy required smart contracts.
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

pub fun testSimpleTransaction() {
    let sign = blockchain.createAccount()
    blockchain.useConfiguration(Test.Configuration({
        "../contracts/utility/FungibleToken.cdc": accounts["FungibleToken"]!.address
    }))
    let txCode = Test.readFile("../../../transactions/demo.cdc")
    assert(txExecutor(txCode, [sign], []))
}

pub fun testCreateOpenOffers() {
    blockchain.useConfiguration(Test.Configuration({
        "../contracts/Offers.cdc": accounts["Offers"]!.address
    }))
    executeSetupAccountTx(accounts["offeree"]!)
}


////////////////
/// Helpers ///
///////////////

pub fun txExecutor(_ txCode: String, _ signers: [Test.Account], _ arguments: [AnyStruct]): Bool {
    let tx = Test.Transaction(
        code: txCode,
        authorizers: [],
        signers: signers,
        arguments: arguments,
    )
    let txResult = blockchain.executeTransaction(tx)
    if let err = txResult.error {
        panic(err.message)
    }
    return txResult.status == Test.ResultStatus.succeeded
}

pub fun executeSetupAccountTx(_ signer: Test.Account) {
    let txCode = Test.readFile("../../../transactions/setup_account.cdc")
    assert(
        txExecutor(txCode, [signer], []),
        message: "Failed to install OpenOffers resource in given offeree account"
    )
}