import ExampleNFT from "../../../../../contracts/utility/ExampleNFT.cdc"

pub fun main(): Type {
    return Type<@ExampleNFT.NFT>()
}