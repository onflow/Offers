import ExampleNFT from "../../../../../contracts/utility/ExampleNFT.cdc"

pub fun main(): Type {
    let exampleNFTType = Type<@ExampleNFT.NFT>()
    return exampleNFTType
}