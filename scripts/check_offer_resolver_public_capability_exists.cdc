import Resolver from "ResolverAccount"
import ExampleOfferResolver from "ExampleOfferResolverAccount"

pub fun main(target: Address): Bool {
    let capRef = getAccount(target).getCapability<&ExampleOfferResolver.OfferResolver{Resolver.ResolverPublic}>(
        Resolver.getResolverPublicPath()
    )!

    return capRef.check()
}