import Resolver from "./Resolver.cdc"
import NonFungibleToken from "./core/NonFungibleToken.cdc"
import MetadataViews from "./core/MetadataViews.cdc"

pub contract ExampleOfferResolver {

    pub let ExampleOfferResolverStoragePath: StoragePath

    /// Current list of supported resolution rules.
    pub enum ResolverType: UInt8 {
        pub case NFT
        pub case MetadataViews
    }

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

                case ResolverType.NFT.rawValue:
                    let nftId = offerFilters["nftId"]! as? UInt64 ?? panic("nftId value is missing or non UInt64 nftId")
                    return item.id == nftId

                default:
                    panic("Invalid Resolver on given offer, Resolver received value is".concat(resolver.toString()))
            }
            return false
        }

        /// Return supported types of the different filter honored by the Resolver.
        pub fun getValidOfferFilterTypes(): {String: String} {
            return {
                "resolver": "UInt8",
                "nftId": "UInt64"
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