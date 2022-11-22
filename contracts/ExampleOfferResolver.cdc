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

            let resolver = offerFilters["resolver"]! as? UInt8 ?? panic("resolver value is missing or non UInt8 resolver")
            switch resolver {

                case Resolver.ResolverType.NFT.rawValue:
                    let nftId = offerFilters["nftId"]! as? UInt64 ?? panic("nftId value is missing or non UInt64 nftId")
                    assert(item.id == nftId, message: "item NFT does not have specified ID")
                    return true

                case Resolver.ResolverType.MetadataViews.rawValue:
                    let views = item.resolveView(Type<MetadataViews.Editions>()) 
                        ?? panic("NFT does not use MetadataViews.Editions")
                    let editions = views as! [MetadataViews.Edition]
                    var hasCorrectMetadataView = false
                    for edition in editions {
                        if edition.name == offerFilters["editionName"]! as! String {
                            hasCorrectMetadataView = true
                            break
                        }
                    }
                    assert(hasCorrectMetadataView == true, message: "editionId does not exist on NFT")
                    return true

                default:
                    panic("Invalid Resolver on given offer, Resolver received value is".concat(resolver.toString()))
            }
            return false
        }

        /// Return supported types of the different filter honored by the Resolver.
        pub fun getValidOfferFilterTypes(): {String: String} {
            return {
                "resolver": "UInt8",
                "nftId": "UInt64",
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