// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract NFTMarketplace is ERC721URIStorage, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 private _nextTokenId;
    address private _owner;

    struct NFTListing {
        uint256 price;
        address seller;
    }

    mapping(uint256 => NFTListing) private _listings;

    event NFTListed(uint256 tokenId, uint256 price, address seller);
    event NFTSold(uint256 tokenId, uint256 price, address seller, address buyer);
    event MinterAdded(address minter);
    event MinterRemoved(address minter);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() ERC721("NFTMarketplace", "NFTM") {
        _owner = msg.sender;
        _grantRole(MINTER_ROLE, msg.sender);
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    function mint(address to, string memory tokenURI) external onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        return tokenId;
    }

    function listNFT(uint256 tokenId, uint256 price) external {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        require(price > 0, "Price must be greater than zero");

        _listings[tokenId] = NFTListing(price, msg.sender);
        emit NFTListed(tokenId, price, msg.sender);
    }

    function buyNFT(uint256 tokenId) external payable {
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

    function cancelListing(uint256 tokenId) external {
        require(_listings[tokenId].seller == msg.sender, "Not the seller");
        delete _listings[tokenId];
    }

    function getListing(uint256 tokenId) external view returns (NFTListing memory) {
        return _listings[tokenId];
    }

    function grantMinterRole(address minter) external onlyOwner {
        grantRole(MINTER_ROLE, minter);
        emit MinterAdded(minter);
    }

    function revokeMinterRole(address minter) external onlyOwner {
        revokeRole(MINTER_ROLE, minter);
        emit MinterRemoved(minter);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        _revokeRole(MINTER_ROLE, _owner);
        _grantRole(MINTER_ROLE, newOwner);
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(_owner).transfer(balance);
    }
}
