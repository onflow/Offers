import NonFungibleToken from "./utility/NonFungibleToken.cdc"
import MetadataViews from "./utility/MetadataViews.cdc"

pub contract Resolver {
    // Current list of supported resolution rules.
    pub enum ResolverType: UInt8 {
        pub case NFT
        pub case MetadataViewsEditions
    }

    // Public resource interface that defines a method signature for checkOfferResolver
    // which is used within the Resolver resource for offer acceptance validation
    pub resource interface ResolverPublic {
        pub fun checkOfferResolver(
         item: &{NonFungibleToken.INFT, MetadataViews.Resolver},
         offerParamsString: {String:String},
         offerParamsUInt64: {String:UInt64},
         offerParamsUFix64: {String:UFix64}): Bool
    }

    pub fun getResolverPublicPath(): PublicPath {
        return /public/GenericOfferResolverPublicPath
    }
}