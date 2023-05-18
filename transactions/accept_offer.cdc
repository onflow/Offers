import Offers from "../contracts/Offers.cdc"
import FungibleToken from "../contracts/core/FungibleToken.cdc"
import NonFungibleToken from "../contracts/core/NonFungibleToken.cdc"
import ExampleToken from "../contracts/core/ExampleToken.cdc"
import ExampleNFT from "../contracts/core/ExampleNFT.cdc"

/// Transaction used to accept the offer by the seller.
///
/// # Params
/// @param ndtId ID of the NFT that would be sell when consuming offer
/// @param offerId ID of the offer resource that get accepted using this transaction
/// @param openOffersHolder Address of the account which holds offer resource
/// @param commissionReceiver Address that receives the commission after fulfilment or accpetance of the offer
transaction(nftId: UInt64, offerId: UInt64, openOffersHolder: Address, commissionReceiver: Address) {

    let openOfferPublic: &Offers.OpenOffers{Offers.OpenOffersPublic}
    let offer: &{Offers.OfferPublic}
    let receiverCapability: Capability<&{FungibleToken.Receiver}>
    let nftCollection: &NonFungibleToken.Collection
    let commissionReceiverCap: Capability<&{FungibleToken.Receiver}>

    prepare(signer: AuthAccount) {
        // Get the OpenOffers resource
        self.openOfferPublic = getAccount(openOffersHolder)
            .getCapability<&Offers.OpenOffers{Offers.OpenOffersPublic}>(
                Offers.OpenOffersPublicPath
            )
            .borrow()
            ?? panic("Could not borrow OpenOffers from provided address")
        
        // Retrieve the receiver capability
        self.receiverCapability = signer.getCapability<&{FungibleToken.Receiver}>(ExampleToken.ReceiverPublicPath)
        assert(self.receiverCapability.borrow() != nil, message: "Missing or mis-typed given valut receiver")

        // Retrieve the commission capability
        self.commissionReceiverCap = getAccount(commissionReceiver).getCapability<&{FungibleToken.Receiver}>(ExampleToken.ReceiverPublicPath)
        assert(self.commissionReceiverCap.borrow() != nil, message: "Missing or mis-typed given commission receiver vault")
        
        // Get the OpenOffers details
        self.offer = self.openOfferPublic.borrowOffer(offerId: offerId)
            ?? panic("Unable to borrow the offer")

        // Get the NFT resource and withdraw the NFT from the signers account
        self.nftCollection = signer.borrow<&NonFungibleToken.Collection>(from: ExampleNFT.CollectionStoragePath)
            ?? panic("Cannot borrow NFT collection receiver from account")
    }

    execute {
        let item <- self.nftCollection.withdraw(withdrawID: nftId) as! @ExampleNFT.NFT
        self.offer.accept(
            item: <- item,
            receiverCapability: self.receiverCapability,
            commissionRecipient: self.commissionReceiverCap
        )
    }
}
