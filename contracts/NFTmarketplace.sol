// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTMarketplace {
  // NFTs from different collections can be sold on the marketplace, so a listing
  // must contain the NFT contrat address, tokenID, seller address, and sale price.
  struct Listing {
    uint256 price;
    address seller;
  }

  // conctract address -> (Token ID -> Listing Data)
  mapping(address => mapping(uint256 => Listing)) public listings;

  // modifiers
  modifier isNFTOwner(address nftAddress, uint256 tokenId){
    require(IERC721(nftAddress).ownerOf(tokenId) == msg.sender, "Not the owner.");
    _;
  }

  // Price must be more than 0
  modifier validPrice(uint256 _price) {
    require(_price > 0, "Price must be > 0");
    _;
  }

  // Specified NFT must not be listed.
  modifier isNotListed(address nftAddress, uint256 tokenId){
    require(listings[nftAddress][tokenId].price == 0, "Already listed");
    _;
  }

  // Specified NFT must be listed
  modifier isListed(address nftAddress, uint256 tokenId) {
      require(listings[nftAddress][tokenId].price > 0, "Not listed");
      _;
  }

  // Events
  // Emitted when an event is created
  event ListingCreated(
      address nftAddress,
      uint256 tokenId,
      uint256 price,
      address seller
  );

  event ListingCancelled(address nftAddress, uint256 tokenId, address seller);

  function createListing(
    address nftAddress,
    uint256 tokenId,
    uint256 price
  ) external 
  isNotListed(nftAddress, tokenId)
  isNFTOwner(nftAddress, tokenId)
  validPrice(price)
 {
    // Caller must be owner of the NFT, and has approved the marketplace contract
    // to transfer on their behalf.
    IERC721 nftContract = IERC721(nftAddress);
    require(nftContract.ownerOf(tokenId) == msg.sender, "Not the owner.");
    require(
            nftContract.isApprovedForAll(msg.sender, address(this)) ||
                nftContract.getApproved(tokenId) == address(this),
            "No approval for NFT"
        );

    // Add the listing to our mapping.
    listings[nftAddress][tokenId] = Listing({
      price:price,
      seller: msg.sender
    });

    emit ListingCreated(nftAddress, tokenId, price, msg.sender);
  }

  // Cancel listing.
  function cancelListing(address nftAddress, uint256 tokenId) 
  external isListed(nftAddress, tokenId)
  isNFTOwner(nftAddress, tokenId){
    // Delete the list from our mapping
    // Freeing up storage saves gas!
    delete listings[nftAddress][tokenId];

    // Emit the event
    emit ListingCancelled(nftAddress, tokenId, msg.sender);
  }

  event ListingUpdated(
    address nftAddress,
    uint256 tokenId,
    uint256 newPrice,
    address seller
);

  function updateListing(
      address nftAddress,
      uint256 tokenId,
      uint256 newPrice
  ) external isListed(nftAddress, tokenId) isNFTOwner(nftAddress, tokenId) validPrice(newPrice) {
      // Update the listing price
      listings[nftAddress][tokenId].price = newPrice;

    // Emit the event
    emit ListingUpdated(nftAddress, tokenId, newPrice, msg.sender);
    }

    event ListingPurchased(address nftAddress, uint256 tokenId, address seller, address buyer);

    function purchaseListing(address nftAddress, uint256 tokenId) 
    external payable isListed(nftAddress, tokenId)
    {
      // Load the listing in a local copy
      Listing memory listing = listings[nftAddress][tokenId];
      // Buyer must have enough ETH. 
      require(msg.value == listing.price, "Incorrect ETH supplied.");

      // Delete listing from storage
      delete listings[nftAddress][tokenId];

      // Transfer NFT from seller to buyer.abi
      IERC721(nftAddress).safeTransferFrom(listing.seller, msg.sender, tokenId);

      // Transfer ETH sent from buyer to seller. 
      (bool sent,) = payable(listing.seller).call{value:msg.value}("");
      require(sent, "Failed to transfer ETH");

      // Emit the event
      emit ListingPurchased(nftAddress, tokenId, listing.seller, msg.sender);

    }
}