import PaymentHandler from "./PaymentHandler.cdc"
import FungibleToken from "./utility/FungibleToken.cdc"
import FungibleTokenSwitchboard from "./utility/FungibleTokenSwitchboard.cdc"

pub contract DefaultPaymentHandler {

    pub let DefaultPaymentHandlerStoragePath: StoragePath

    pub resource DefaultHandler: PaymentHandler.PaymentHandlerPublic {
        
        /// An Offeror can provide different implementation according to which payment get settled during the acceptance of the offer.
        ///
        /// @param receiverCap Capability which would receive funds.
        /// @param allowedVaultType Allowed vault type for the payment settlement
        /// @return A boolean that indicates whether given `receiverCap` honors the handler or not.
        ///
        pub fun checkValidVaultType(receiverCap: Capability<&{FungibleToken.Receiver}>, allowedVaultType: Type) : Bool {
            if receiverCap.getType() == allowedVaultType {
                return true
            } else if receiverCap.isInstance(FungibleTokenSwitchboard.Switchboard.getType()) {
                // Access the switchboard public capability to know whether the `allowedVaultType` is registered with switchboard or not.
                if let switchboardPublicRef = getAccount(receiverCap.address).getCapability<&{FungibleTokenSwitchboard.SwitchboardPublic}>(FungibleTokenSwitchboard.PublicPath).borrow() {
                    let acceptedTypes = switchboardPublicRef.getVaultTypes()
                    for aType in acceptedTypes {
                        if aType == allowedVaultType {
                            return true
                        }
                    }
                }
            }
            return false
        }
    }

    pub fun createDefaultHandler(): @DefaultHandler {
        return <-create DefaultHandler()
    }

    init() {
        self.DefaultPaymentHandlerStoragePath = /storage/DefaultPaymentHandler
    }

}