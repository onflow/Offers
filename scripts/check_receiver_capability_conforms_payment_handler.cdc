import PaymentHandler from "../contracts/PaymentHandler.cdc"
import FungibleToken from "../contracts/core/FungibleToken.cdc"
import ExampleToken from "../contracts/core/ExampleToken.cdc"

pub fun main(receiver: Address, receiverPath: PublicPath, defaultPaymentHandlerOwner: Address): Bool {
    let paymentHandlerRef = getAccount(defaultPaymentHandlerOwner)
        .getCapability<&{PaymentHandler.PaymentHandlerPublic}>(PaymentHandler.getPaymentHandlerPublicPath())
        .borrow()
        ?? panic("Not able to borrow the payment handler")
    let receiverCap = getAccount(receiver).getCapability<&{FungibleToken.Receiver}>(receiverPath)
    return paymentHandlerRef.checkValidVaultType(receiverCap: receiverCap, allowedVaultType: Type<@ExampleToken.Vault>())
}