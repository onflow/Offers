import NonFungibleToken from "./utility/NonFungibleToken.cdc"
import MetadataViews from "./utility/MetadataViews.cdc"

pub contract Resolver {
    /// Current list of supported resolution rules.
    pub enum ResolverType: UInt8 {
        pub case NFT
        pub case MetadataViewsEditions
    }

    /// Public resource interface that defines a method signature for checkOfferResolver
    /// which is used within the Resolver resource for offer acceptance validation
    pub resource interface ResolverPublic {

        /// Checks whether given items follows the same constraints as given offer.  
        ///
        /// @param item: NFT which needs to be checked
        /// @param offerFilters: Dictionary that contains the trait of NFT in `AnyStruct` datatype.
        /// @return A boolean that indicates whether given `item` honors the resolver or not.
        ///
        pub fun checkOfferResolver(
         item: &{NonFungibleToken.INFT, MetadataViews.Resolver},
         offerFilters: {String: AnyStruct}
        ): Bool

        /// Return supported types of the different filter honored by the Resolver.
        pub fun getValidOfferFilterTypes(): {String: String}
    }

    pub fun getResolverPublicPath(): PublicPath {
        return /public/GenericOfferResolverPublicPath
    }
}