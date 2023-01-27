// This script reads the balance field of an account's ExampleToken Balance
import FungibleToken from "CoreContractsAccount"
import ExampleToken from "CoreContractsAccount"

pub fun main(account: Address): UFix64 {
    let acct = getAccount(account)
    let vaultRef = acct.getCapability(ExampleToken.BalancePublicPath)
        .borrow<&ExampleToken.Vault{FungibleToken.Balance}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    return vaultRef.balance
}