import PaymentHandler from "PaymentHandlerAccount"
import FungibleToken from "CoreContractsAccount"
import ExampleToken from "CoreContractsAccount"

pub fun main(receiver: Address, receiverPath: PublicPath, defaultPaymentHandlerOwner: Address): Bool {
    let paymentHandlerRef = getAccount(defaultPaymentHandlerOwner)
        .getCapability<&{PaymentHandler.PaymentHandlerPublic}>(PaymentHandler.getPaymentHandlerPublicPath())
        .borrow()
        ?? panic("Not able to borrow the payment handler")
    let receiverCap = getAccount(receiver).getCapability<&{FungibleToken.Receiver}>(receiverPath)
    return paymentHandlerRef.checkValidVaultType(receiverCap: receiverCap, allowedVaultType: Type<@ExampleToken.Vault>())
}