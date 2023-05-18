import OfferMatcher from "../contracts/OfferMatcher.cdc"
import ExampleOfferMatcher from "../contracts/ExampleOfferMatcher.cdc"

/// This transaction installs the OpenOfferMatcher ressource in an account.
transaction {

    prepare(acct: AuthAccount) {

        // If the account doesn't already have a OpenOfferMatcher
        if acct.borrow<&ExampleOfferMatcher.OpenOfferMatcher{OfferMatcher.OfferMatcherPublic}>(from: ExampleOfferMatcher.ExampleOpenOfferMatcherStoragePath) == nil {

            // Create a new empty OpenOfferMatcher
            let offerMatcher <- ExampleOfferMatcher.createOpenOfferMatcher() as! @ExampleOfferMatcher.OpenOfferMatcher
            
            // save it to the account
            acct.save(<-offerMatcher, to: ExampleOfferMatcher.ExampleOpenOfferMatcherStoragePath)

            // create a public capability for the OpenOffers
            acct.link<&ExampleOfferMatcher.OpenOfferMatcher{OfferMatcher.OfferMatcherPublic}>(OfferMatcher.getOfferMatcherPublicPath(), target: ExampleOfferMatcher.ExampleOpenOfferMatcherStoragePath)
        }
    }
}