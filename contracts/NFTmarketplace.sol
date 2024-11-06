// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Custom errors
error PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
error ItemNotForSale(address nftAddress, uint256 tokenId);
error NotListed(address nftAddress, uint256 tokenId);
error AlreadyListed(address nftAddress, uint256 tokenId);
error NoProceeds();
error NotOwner();
error NotApprovedForMarketplace();

contract NFTMarketplace is ReentrancyGuard {
    struct Listing {
        uint256 price;
        address seller;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;
    mapping(address => uint256) s_proceeds; // Holds proceeds from sells.

    /**
     * ----------------------------------------------------------------
     * modifiers
     * ----------------------------------------------------------------
     **/
    modifier onlyOwner(
        address nftAddress,
        uint256 tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(nftAddress);
        if (nft.ownerOf(tokenId) != spender) {
            revert NotOwner();
        }
        _;
    }

    modifier validPrice(uint256 _price) {
        require(_price > 0, "Price must be > 0");
        _;
    }

    modifier isNotListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = listings[nftAddress][tokenId];
        if (listing.price > 0) {
            revert AlreadyListed(nftAddress, tokenId);
        }
        _;
    }

    modifier isListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = listings[nftAddress][tokenId];
        if (listing.price <= 0) {
            revert NotListed(nftAddress, tokenId);
        }
        _;
    }

    /**
     * ----------------------------------------------------------------
     * Events
     * ----------------------------------------------------------------
     */
    event ListingCreated(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        address seller
    );
    event ItemCanceled(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );
    event ListingUpdated(
        address nftAddress,
        uint256 tokenId,
        uint256 newPrice,
        address seller
    );
    event ListingPurchased(
        address nftAddress,
        uint256 tokenId,
        address seller,
        address buyer
    );

    function createListing(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    )
        external
        isNotListed(nftAddress, tokenId)
        onlyOwner(nftAddress, tokenId, msg.sender)
        validPrice(price)
    {
        IERC721 nft = IERC721(nftAddress);
        require(
            nft.isApprovedForAll(msg.sender, address(this)) ||
                nft.getApproved(tokenId) == address(this),
            "No approval for NFT"
        );

        // Add the listing to our mapping.
        listings[nftAddress][tokenId] = Listing(price, msg.sender);

        emit ListingCreated(nftAddress, tokenId, price, msg.sender);
    }

    // Cancel listing.
    function cancelListing(
        address nftAddress,
        uint256 tokenId
    )
        external
        isListed(nftAddress, tokenId)
        onlyOwner(nftAddress, tokenId, msg.sender)
    {
        // Delete the list from our mapping
        // Freeing up storage saves gas!
        delete listings[nftAddress][tokenId];

        // Emit the event
        emit ItemCanceled(msg.sender, nftAddress, tokenId);
    }

    function updateListing(
        address nftAddress,
        uint256 tokenId,
        uint256 newPrice
    )
        external
        isListed(nftAddress, tokenId)
        onlyOwner(nftAddress, tokenId, msg.sender)
        validPrice(newPrice)
        nonReentrant
    {
        // Update the listing price
        listings[nftAddress][tokenId].price = newPrice;
        emit ListingUpdated(nftAddress, tokenId, newPrice, msg.sender);
    }

    function purchaseListing(
        address nftAddress,
        uint256 tokenId
    ) external payable isListed(nftAddress, tokenId) {
        Listing memory listing = listings[nftAddress][tokenId];
        require(msg.value == listing.price, "Incorrect ETH supplied.");

        s_proceeds[msg.sender] += msg.value;
        delete listings[nftAddress][tokenId];

        IERC721(nftAddress).safeTransferFrom(
            listing.seller,
            msg.sender,
            tokenId
        );

        emit ListingPurchased(nftAddress, tokenId, listing.seller, msg.sender);
    }

    function withdrawProceeds() external {
        if (s_proceeds[msg.sender] <= 0) {
            revert NoProceeds();
        }

        s_proceeds[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{
            value: s_proceeds[msg.sender]
        }("");
        require(success, "Failed to withdraw");
    }

    function getListing(
        address nftAddress,
        uint256 tokenId
    ) external view returns (Listing memory) {
        return listings[nftAddress][tokenId];
    }

    function getProceeds(address seller) external view returns (uint256) {
        return s_proceeds[seller];
    }
}
