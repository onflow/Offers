import FungibleToken from "./utility/FungibleToken.cdc"

/// PaymentHandler contract
/// It is generic payment handler, Provides a public interface ,i.e. `PaymentHandlerPublic`
/// that would be used to validate the vault type when accepting the offer.
pub contract PaymentHandler {

    /// Public interface helps to discover whether given FT reciever has valid vault type
    pub resource interface PaymentHandlerPublic {
        
        /// An Offeror can provide different implementation according to which payment get settled during the acceptance of the offer.
        ///
        /// @param receiverCap Capability which would receive funds.
        /// @param allowedVaultType Allowed vault type for the payment settlement
        /// @return A boolean that indicates whether given `receiverCap` honors the handler or not.
        ///
        pub fun checkValidVaultType(receiverCap: Capability<&{FungibleToken.Receiver}>, allowedVaultType: Type) : Bool

    }

    /// Return the generic public path
    pub fun getPaymentHandlerPublicPath(): PublicPath {
        return /public/GenericPaymmentHandlerPublicPath
    }
}