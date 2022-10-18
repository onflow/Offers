import Resolver from "../contracts/Resolver.cdc"
import ExampleOfferResolver from "../contracts/ExampleOfferResolver.cdc"

pub fun main(target: Address): Bool {
    let capRef = getAccount(target).getCapability<&ExampleOfferResolver.OfferResolver{Resolver.ResolverPublic}>(
        Resolver.getResolverPublicPath()
    )!

    return capRef.check()
}