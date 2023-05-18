// This transaction is a template for a transaction to allow 
// anyone to add a Vault resource to their account so that 
// they can use the exampleToken

import FungibleToken from "../../../../../contracts/core/FungibleToken.cdc"
import ExampleToken from "../../../../../contracts/core/ExampleToken.cdc"
import TestToken from "../contracts/TestToken.cdc"

transaction(tokenType: UInt8) {

    var vaultStoragePath: StoragePath
    var vaultReceiverPath: PublicPath
    var vaultBalancePath: PublicPath

    prepare(signer: AuthAccount) {

        self.vaultStoragePath = ExampleToken.VaultStoragePath
        self.vaultReceiverPath = ExampleToken.ReceiverPublicPath
        self.vaultBalancePath = ExampleToken.BalancePublicPath

        switch tokenType {
            case 1: 
                // Return early if the account already stores a ExampleToken Vault
                if signer.borrow<&ExampleToken.Vault>(from: self.vaultStoragePath) != nil {
                    return
                }

                // Create a new ExampleToken Vault and put it in storage
                signer.save(
                    <-ExampleToken.createEmptyVault(),
                    to: self.vaultStoragePath
                )

                // Create a public capability to the Vault that only exposes
                // the deposit function through the Receiver interface
                signer.link<&ExampleToken.Vault{FungibleToken.Receiver}>(
                    self.vaultReceiverPath,
                    target: self.vaultStoragePath
                )

                // Create a public capability to the Vault that only exposes
                // the balance field through the Balance interface
                signer.link<&ExampleToken.Vault{FungibleToken.Balance}>(
                    self.vaultBalancePath,
                    target: self.vaultStoragePath
                )

            case 2:
                self.vaultStoragePath = TestToken.VaultStoragePath
                self.vaultReceiverPath = TestToken.ReceiverPublicPath
                self.vaultBalancePath = TestToken.BalancePublicPath

                // Return early if the account already stores a TestToken Vault
                if signer.borrow<&TestToken.Vault>(from: self.vaultStoragePath) != nil {
                    return
                }

                // Create a new TestToken Vault and put it in storage
                signer.save(
                    <-TestToken.createEmptyVault(),
                    to: self.vaultStoragePath
                )

                // Create a public capability to the Vault that only exposes
                // the deposit function through the Receiver interface
                signer.link<&TestToken.Vault{FungibleToken.Receiver}>(
                    self.vaultReceiverPath,
                    target: self.vaultStoragePath
                )

                // Create a public capability to the Vault that only exposes
                // the balance field through the Balance interface
                signer.link<&TestToken.Vault{FungibleToken.Balance}>(
                    self.vaultBalancePath,
                    target: self.vaultStoragePath
                )

            default:
                panic("Invalid token type")
        }
    }
}