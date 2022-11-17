import Resolver from "./Resolver.cdc"
import NonFungibleToken from "./utility/NonFungibleToken.cdc"
import MetadataViews from "./utility/MetadataViews.cdc"

pub contract ExampleOfferResolver {

    pub let ExampleOfferResolverStoragePath: StoragePath

    /// Resolver resource holds the Offer exchange resolution rules.
    pub resource OfferResolver: Resolver.ResolverPublic {
        /// checkOfferResolver
        /// Holds the validation rules for resolver each type of supported ResolverType
        /// Function returns TRUE if the provided nft item passes the criteria for exchange
        pub fun checkOfferResolver(
         item: &AnyResource{NonFungibleToken.INFT, MetadataViews.Resolver},
         offerFilters: {String: AnyStruct}
         ): Bool {
            if offerFilters["resolver"]! as! String == Resolver.ResolverType.NFT.rawValue.toString() {
                assert(item.id.toString() == offerFilters["nftId"]! as! String, message: "item NFT does not have specified ID")
                return true
            } else if offerFilters["resolver"]! as! String == Resolver.ResolverType.MetadataViewsEditions.rawValue.toString() {
                if let views = item.resolveView(Type<MetadataViews.Editions>()) {
                    let editions = views as! [MetadataViews.Edition]
                    var hasCorrectMetadataView = false
                    for edition in editions {
                        if edition.name == offerFilters["editionName"]! as! String {
                            hasCorrectMetadataView = true
                        }
                    }
                    assert(hasCorrectMetadataView == true, message: "editionId does not exist on NFT")
                    return true
                } else {
                    panic("NFT does not use MetadataViews.Editions")
                }
            } else {
                panic("Invalid Resolver on Offer")
            }

            return false
        }

        /// Return supported types of the different filter honored by the Resolver.
        pub fun getValidOfferFilterTypes(): {String: String} {
            return {
                "resolver": "String",
                "nftId": "String",
                "editionName": "String"
            }
        }
    }

    pub fun createOfferResolver(): @OfferResolver {
        return <-create OfferResolver()
    }

    init() {
        self.ExampleOfferResolverStoragePath = /storage/ExampleOfferResolver
    }
}