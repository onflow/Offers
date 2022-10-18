import Offers from "../contracts/Offers.cdc"
import FungibleToken from "../contracts/utility/FungibleToken.cdc"
import NonFungibleToken from "../contracts/utility/NonFungibleToken.cdc"
import ExampleToken from "../contracts/utility/ExampleToken.cdc"
import ExampleNFT from "../contracts/utility/ExampleNFT.cdc"

transaction(nftId: UInt64, offerId: UInt64, openOffersHolder: Address) {

    let openOfferPublic: &Offers.OpenOffers{Offers.OpenOffersPublic}
    let offer: &{Offers.OfferPublic}
    let receiverCapability: Capability<&{FungibleToken.Receiver}>
    let nftCollection: &NonFungibleToken.Collection

    prepare(signer: AuthAccount) {
        // Get the OpenOffers resource
        self.openOfferPublic = getAccount(openOffersHolder)
            .getCapability<&Offers.OpenOffers{Offers.OpenOffersPublic}>(
                Offers.OpenOffersPublicPath
            )!
            .borrow()
            ?? panic("Could not borrow OpenOffers from provided address")
        
        // Retrieve the receiver capability
        self.receiverCapability = signer.getCapability<&{FungibleToken.Receiver}>(ExampleToken.ReceiverPublicPath)
        assert(self.receiverCapability.borrow() != nil, message: "Missing or mis-typed given valut receiver")
        
        // Get the OpenOffers details
        self.offer = self.openOfferPublic.borrowOffer(offerId: offerId)
            ?? panic("Unable to borrow the offer")

        // Get the NFT ressource and withdraw the NFT from the signers account
        self.nftCollection = signer.borrow<&NonFungibleToken.Collection>(from: ExampleNFT.CollectionStoragePath)
            ?? panic("Cannot borrow NFT collection receiver from account")
    }

    execute {
        self.offer.accept(
            item: <- (self.nftCollection.withdraw(withdrawID: nftId) as! @ExampleNFT.NFT),
            receiverCapability: self.receiverCapability
        )
    }
}
