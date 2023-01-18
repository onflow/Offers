
/// This transaction is a template for a transaction
/// to create a new link in their account to be used for receiving royalties
/// This transaction can be used for any fungible token, which is specified by the `vaultPath` argument
/// 
import FungibleToken from "../../../../../contracts/core/FungibleToken.cdc"
import MetadataViews from "../../../../../contracts/core/MetadataViews.cdc"
import FungibleTokenSwitchboard from "../../../../../contracts/core/FungibleTokenSwitchboard.cdc"

transaction(vaultPath: StoragePath) {

    prepare(signer: AuthAccount) {

        // Return early if the account doesn't have a FungibleToken Vault
        if signer.borrow<&FungibleToken.Vault>(from: vaultPath) == nil {
            panic("A vault for the specified fungible token path does not exist")
        }

        // Create a public capability to the Vault that only exposes
        // the deposit function through the Receiver interface
        let capability = signer.link<&{FungibleToken.Receiver, FungibleToken.Balance}>(
            MetadataViews.getRoyaltyReceiverPublicPath(),
            target: vaultPath
        )!

        // Make sure the capability is valid
        if !capability.check() { panic("Beneficiary capability is not valid!") }
    }
}