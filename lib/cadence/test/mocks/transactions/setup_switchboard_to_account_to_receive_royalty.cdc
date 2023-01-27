
/// This transaction is a template for a transaction
/// to create a new link in their account to be used for receiving royalties
/// This transaction can be used for any fungible token, which is specified by the `vaultPath` argument
/// 
import FungibleToken from "CoreContractsAccount"
import MetadataViews from "CoreContractsAccount"
import FungibleTokenSwitchboard from "CoreContractsAccount"

transaction(vaultPath: StoragePath, receiverPath: PublicPath) {

    prepare(signer: AuthAccount) {

        // Return early if the account doesn't have a FungibleToken Vault
        if signer.borrow<&FungibleToken.Vault>(from: vaultPath) == nil {
            panic("A vault for the specified fungible token path does not exist")
        }

        let receiverCap = signer.getCapability<&{FungibleToken.Receiver}>(receiverPath)

        // Create the switchboard resource
        signer.save(<-FungibleTokenSwitchboard.createSwitchboard(), to: FungibleTokenSwitchboard.StoragePath)

        // Create a public capability to the Vault that only exposes
        // the deposit function through the Receiver interface
        let capability = signer.link<&{FungibleToken.Receiver}>(
            MetadataViews.getRoyaltyReceiverPublicPath(),
            target: FungibleTokenSwitchboard.StoragePath
        )!

        signer.link<&{FungibleTokenSwitchboard.SwitchboardPublic}>(
            FungibleTokenSwitchboard.PublicPath,
            target: FungibleTokenSwitchboard.StoragePath
        ) 

        // Make sure the capability is valid
        if !capability.check() { panic("Beneficiary capability is not valid!") }

        let switchboardRef = signer.borrow<&FungibleTokenSwitchboard.Switchboard>(from: FungibleTokenSwitchboard.StoragePath)!
        switchboardRef.addNewVault(capability: receiverCap)
    }
}