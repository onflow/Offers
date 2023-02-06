import OfferMatcher from "./OfferMatcher.cdc"
import NonFungibleToken from "./core/NonFungibleToken.cdc"
import MetadataViews from "./core/MetadataViews.cdc"

/// ExampleOfferMatcher
///
/// This contract is just an example implementation of the `OfferMatcher` contract.
/// The idea behind to develop this is to showcase the design strength and how much
/// useful it can be if marketplaces or third party applications develop their usecase-specific
/// implementation of the `OfferMatcher.OfferMatcherPublic` resource.
///
/// It allows following - {"nftId": "1"} kind of filter for an offer. It only checks whether
/// given `item` has `nftId` equals to the filter value i.e `offerFilters["nftId"]`
///
pub contract ExampleOfferMatcher {

    pub let ExampleOpenOfferMatcherStoragePath: StoragePath

    /// Current list of supported resolution rules.
    pub enum OfferMatcherType: UInt8 {
        pub case NFT
        pub case MetadataViews
    }

    /// OpenOfferMatcher resource holds the Offer exchange resolution rules.
    pub resource OpenOfferMatcher: OfferMatcher.OfferMatcherPublic {
        /// checkOfferMatches
        /// Holds the validation rules for offerMatcher each type of supported OfferMatcherType
        /// Function returns TRUE if the provided nft item passes the criteria for exchange
        pub fun checkOfferMatches(
         item: &AnyResource{NonFungibleToken.INFT, MetadataViews.Resolver},
         offerFilters: {String: AnyStruct}
         ): Bool {

            let matcher = offerFilters["matcher"]! as? UInt8 ?? panic("Matcher value is missing or non UInt8 matcher")
            switch matcher {

                case OfferMatcherType.NFT.rawValue:
                    let nftId = offerFilters["nftId"]! as? UInt64 ?? panic("nftId value is missing or non UInt64 nftId")
                    return item.id == nftId

                default:
                    panic("Invalid OfferMatcher on given offer, OfferMatcher received value is".concat(matcher.toString()))
            }
            return false
        }

        /// Return supported types of the different filter honored by the OfferMatcher.
        pub fun getValidOfferFilterTypes(): {String: String} {
            return {
                "matcher": "UInt8",
                "nftId": "UInt64"
            }
        }
    }

    pub fun createOpenOfferMatcher(): @OpenOfferMatcher {
        return <-create OpenOfferMatcher()
    }

    init() {
        self.ExampleOpenOfferMatcherStoragePath = /storage/ExampleOpenOfferMatcher
    }
}