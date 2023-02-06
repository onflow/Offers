import PaymentHandler from "../contracts/PaymentHandler.cdc"
import FungibleToken from "../contracts/core/FungibleToken.cdc"
import ExampleToken from "../contracts/core/ExampleToken.cdc"

/// This script tells whether the given receiver capability conforms with the provided payment handler
///
/// # Params
/// @param receiver Address of the account who holds receiver capability
/// @param receiverPath Public path where receiver capability holds
/// @param paymentHandler Address of the account which holds the payment handler
///
/// # Returns
/// @return Boolean value, `True` if provided receiver holds the valid Fungible token capability, Otherwise `False`
///
pub fun main(receiver: Address, receiverPath: PublicPath, paymentHandler: Address): Bool {
    let paymentHandlerRef = getAccount(paymentHandler)
        .getCapability<&{PaymentHandler.PaymentHandlerPublic}>(PaymentHandler.getPaymentHandlerPublicPath())
        .borrow()
        ?? panic("Not able to borrow the payment handler")
    let receiverCap = getAccount(receiver).getCapability<&{FungibleToken.Receiver}>(receiverPath)
    return paymentHandlerRef.checkValidVaultType(receiverCap: receiverCap, allowedVaultType: Type<@ExampleToken.Vault>())
}