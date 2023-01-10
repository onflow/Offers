import Resolver from "../contracts/Resolver.cdc"
import ExampleOfferResolver from "../contracts/ExampleOfferResolver.cdc"

/// This transaction installs the OfferResolver ressource in an account.
transaction {

    prepare(acct: AuthAccount) {

        // If the account doesn't already have a OfferResolver
        if acct.borrow<&ExampleOfferResolver.OfferResolver{Resolver.ResolverPublic}>(from: ExampleOfferResolver.ExampleOfferResolverStoragePath) == nil {

            // Create a new empty OfferResolver
            let offerResolver <- ExampleOfferResolver.createOfferResolver() as! @ExampleOfferResolver.OfferResolver
            
            // save it to the account
            acct.save(<-offerResolver, to: ExampleOfferResolver.ExampleOfferResolverStoragePath)

            // create a public capability for the OpenOffers
            acct.link<&ExampleOfferResolver.OfferResolver{Resolver.ResolverPublic}>(Resolver.getResolverPublicPath(), target: ExampleOfferResolver.ExampleOfferResolverStoragePath)
        }
    }
}