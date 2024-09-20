// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;

    struct NFTListing {
        uint256 price;
        address seller;
    }

    mapping(uint256 => NFTListing) private _listings;

    event NFTListed(uint256 tokenId, uint256 price, address seller);
    event NFTSold(uint256 tokenId, uint256 price, address seller, address buyer);

    constructor() ERC721("NFTMarketplace", "NFTM") {}

    function mint(string memory tokenURI) public returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);
        return tokenId;
    }

    function listNFT(uint256 tokenId, uint256 price) public {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        require(price > 0, "Price must be greater than zero");

        _listings[tokenId] = NFTListing(price, msg.sender);
        emit NFTListed(tokenId, price, msg.sender);
    }

    function buyNFT(uint256 tokenId) public payable {
        NFTListing memory listing = _listings[tokenId];
        require(listing.price > 0, "NFT not for sale");
        require(msg.value >= listing.price, "Insufficient payment");

        address seller = listing.seller;
        uint256 price = listing.price;

        delete _listings[tokenId];
        _transfer(seller, msg.sender, tokenId);

        payable(seller).transfer(price);
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }

        emit NFTSold(tokenId, price, seller, msg.sender);
    }

    function cancelListing(uint256 tokenId) public {
        require(_listings[tokenId].seller == msg.sender, "Not the seller");
        delete _listings[tokenId];
    }

    function getListing(uint256 tokenId) public view returns (NFTListing memory) {
        return _listings[tokenId];
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(owner()).transfer(balance);
    }
}
