import ExampleNFT from "../../../../../contracts/core/ExampleNFT.cdc"

pub fun main(): Type {
    return Type<@ExampleNFT.NFT>()
}