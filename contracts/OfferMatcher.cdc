import NonFungibleToken from "./core/NonFungibleToken.cdc"
import MetadataViews from "./core/MetadataViews.cdc"

/// OfferMatcher
///
pub contract OfferMatcher {
    
    /// Public resource interface that defines a method signature for checkOfferMatches
    /// which is used within the OfferMatcher resource for offer acceptance validation
    pub resource interface OfferMatcherPublic {

        /// Checks whether given items follows the same constraints as given offer.  
        ///
        /// @param item: NFT which needs to be checked
        /// @param offerFilters: Dictionary that contains the trait of NFT in `AnyStruct` datatype.
        /// @return A boolean that indicates whether given `item` honors the offerMatcher or not.
        ///
        pub fun checkOfferMatches(
         item: &{NonFungibleToken.INFT, MetadataViews.Resolver},
         offerFilters: {String: AnyStruct}
        ): Bool

        /// Return supported types of the different filter honored by the Resolver.
        pub fun getValidOfferFilterTypes(): {String: String}
    }

    pub fun getOfferMatcherPublicPath(): PublicPath {
        return /public/GenericOfferMatcherPublicPath
    }
}