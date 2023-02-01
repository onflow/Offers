import PaymentHandler from "./PaymentHandler.cdc"
import FungibleToken from "./core/FungibleToken.cdc"
import FungibleTokenSwitchboard from "./core/FungibleTokenSwitchboard.cdc"

/// DefaultPaymentHandler
///
/// This contract is a "DEFAULT" payment handler, which is used in the `Offers` contract to 
/// resolve payments during offer acceptance. The `Offers` account will own the `DefaultHandler` resource, 
/// which will be used to validate the vault type of the payment receivers, If no explicit payment handler
/// is provided by the prospective buyer.
/// 
/// `DefaultHandler` would be useful to if marketplaces or third party applications only allows given `allowedVaultType`
/// receiver vault or `FungibleTokenSwitchboard.Switchboard` resource.
pub contract DefaultPaymentHandler {

    pub let DefaultPaymentHandlerStoragePath: StoragePath

    pub resource DefaultHandler: PaymentHandler.PaymentHandlerPublic {
        
        /// The Prospective Buyer can provide different implementation according to which payment get settled during the acceptance of the offer.
        ///
        /// @param receiverCap Capability which would receive funds.
        /// @param allowedVaultType Allowed vault type for the payment settlement
        /// @return A boolean that indicates whether given `receiverCap` honors the handler or not.
        ///
        pub fun checkValidVaultType(receiverCap: Capability<&{FungibleToken.Receiver}>, allowedVaultType: Type) : Bool {
            if receiverCap.borrow()!.getType() == allowedVaultType {
                return true
            } else if receiverCap.borrow()!.isInstance(Type<@FungibleTokenSwitchboard.Switchboard>()) {
                // Access the switchboard public capability to know whether the `allowedVaultType` is registered with switchboard or not.
                if let switchboardPublicRef = getAccount(receiverCap.address).getCapability<&{FungibleTokenSwitchboard.SwitchboardPublic}>(FungibleTokenSwitchboard.PublicPath).borrow() {
                    return switchboardPublicRef.getVaultTypes().contains(allowedVaultType)
                }
            }
            return false
        }
    }

    pub fun createDefaultHandler(): @DefaultHandler {
        return <-create DefaultHandler()
    }

    init() {
        self.DefaultPaymentHandlerStoragePath = /storage/FlowOpenMarketPlaceDefaultPaymentHandler
    }

}