import Offers from "../contracts/Offers.cdc"

/// This transaction installs the OpenOffers ressource in an account.

transaction {

    prepare(acct: AuthAccount) {

        // If the account doesn't already have a OpenOffers
        if acct.borrow<&Offers.OpenOffers>(from: Offers.OpenOffersStoragePath) == nil {

            // Create a new empty OpenOffers
            let openOffers <- Offers.createOpenOffers() as! @Offers.OpenOffers
            
            // save it to the account
            acct.save(<-openOffers, to: Offers.OpenOffersStoragePath)

            // create a public capability for the OpenOffers
            acct.link<&Offers.OpenOffers{Offers.OpenOffersPublic}>(Offers.OpenOffersPublicPath, target: Offers.OpenOffersStoragePath)
        }

        let cap = acct.getCapability<&Offers.OpenOffers{Offers.OpenOffersPublic}>(
            Offers.OpenOffersPublicPath
        )

        assert(cap.check(), message: "Public capability doesn't exists")
    }

}