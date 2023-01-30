import FungibleToken from "./core/FungibleToken.cdc"

/// PaymentHandler contract
/// Defines the public interface for PaymentHandler type. 
/// This utility is used to validate the vault type when accepting the offer.
pub contract PaymentHandler {

    /// Public interface helps to discover whether given FT reciever has valid vault type
    pub resource interface PaymentHandlerPublic {
        
        /// Prospective buyers may implement their own PaymentHandlers which can handle validation of specific Vault types as needed.
        ///
        /// @param receiverCap Capability which would receive funds.
        /// @param allowedVaultType Allowed vault type for the payment settlement
        /// @return A boolean that indicates whether given `receiverCap` honors the handler or not.
        ///
        pub fun checkValidVaultType(receiverCap: Capability<&{FungibleToken.Receiver}>, allowedVaultType: Type) : Bool

    }

    /// Return the generic public path
    pub fun getPaymentHandlerPublicPath(): PublicPath {
        return /public/OpenMarketplacePaymentHandlerGenericPublicPath
    }
}