// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFT is ERC721 {
    constructor() ERC721("NFT", "cNFT"){
        // mint 10 NFTS to owner
        for (uint i = 0; i < 10; i++) {
            _mint(msg.sender, i);
        }
    }

    // Hardcoded token URI will return the same metadata for each NFT
    function tokenURI(uint) public pure override returns (string memory){
        return "ipfs://QmTy8w65yBXgyfG2ZBg5TrfB2hPjrDQH3RCQFJGkARStJb";
    }
}