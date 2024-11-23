// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;  // Atualizada para versão 0.8.27

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Croakmarket
/// @notice A secure marketplace contract for minting, listing, purchasing, auctioning, and transferring items.
contract Croakmarket is ReentrancyGuard {

    /// @notice Fee percentage taken by the marketplace (2%).
    uint public constant FEE_PERCENTAGE = 2;

    /// @notice Owner of the contract.
    address public owner;

    /// @notice Structure to represent an item in the marketplace.
    struct Item {
        uint id;
        string name;
        string description;
        uint price;
        address payable seller;
        address owner;
        bool isSold;
    }

    /// @notice Structure to represent an auction in the marketplace.
    struct Auction {
        uint id;
        uint itemId;
        uint startPrice;
        uint currentBid;
        address currentBidder;
        uint endTime;
        bool isActive;
    }

    uint public itemCount = 0;
    uint public auctionCount = 0;

    mapping(uint => Item) public items;
    mapping(uint => Auction) public auctions;

    event ItemMinted(uint indexed itemId, string name, string description, uint price, address indexed seller);
    event ItemPurchased(uint indexed itemId, address indexed buyer, uint price, uint fee);
    event AuctionCreated(uint indexed auctionId, uint itemId, uint startPrice, uint endTime);
    event NewBid(uint indexed auctionId, address indexed bidder, uint bidAmount);
    event AuctionEnded(uint indexed auctionId, uint itemId, address indexed winner, uint finalBid);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier auctionIsActive(uint auctionId) {
        require(auctions[auctionId].isActive, "Auction is not active");
        require(block.timestamp <= auctions[auctionId].endTime, "Auction has ended");
        _;
    }

    constructor() {
        owner = msg.sender; // Set the deployer as the owner
    }

    /// @notice Mints a new item in the marketplace.
    /// @param _name Name of the item.
    /// @param _description Description of the item.
    /// @param _price Price of the item in wei.
    function mintItem(string memory _name, string memory _description, uint _price) external {
        require(_price > 0, "Price must be greater than zero");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");

        itemCount++;
        items[itemCount] = Item(itemCount, _name, _description, _price, payable(msg.sender), msg.sender, false);
        emit ItemMinted(itemCount, _name, _description, _price, msg.sender);
    }

    /// @notice Purchases an item from the marketplace.
    /// @param _itemId ID of the item to purchase.
    function purchaseItem(uint _itemId) external payable nonReentrant {
        Item storage item = items[_itemId];
        require(item.id == _itemId, "Item does not exist");
        require(!item.isSold, "Item has already been sold");
        require(msg.value >= item.price, "Insufficient payment");

        uint fee = (item.price * FEE_PERCENTAGE) / 100;
        uint sellerAmount = item.price - fee;

        item.seller.transfer(sellerAmount);
        payable(owner).transfer(fee);
        item.owner = msg.sender;
        item.isSold = true;

        emit ItemPurchased(_itemId, msg.sender, item.price, fee);
    }

    /// @notice Creates a new auction for an item.
    /// @param _itemId ID of the item to be auctioned.
    /// @param _startPrice Starting price of the auction in wei.
    /// @param _duration Duration of the auction in seconds.
    function createAuction(uint _itemId, uint _startPrice, uint _duration) external {
        Item storage item = items[_itemId];
        require(item.id == _itemId, "Item does not exist");
        require(!item.isSold, "Item has already been sold");
        require(item.owner == msg.sender, "Only the owner can auction this item");
        require(_duration > 0, "Auction duration must be greater than zero");

        auctionCount++;
        uint endTime = block.timestamp + _duration;
        auctions[auctionCount] = Auction(
            auctionCount,
            _itemId,
            _startPrice,
            0,
            address(0),
            endTime,
            true
        );
        emit AuctionCreated(auctionCount, _itemId, _startPrice, endTime);
    }

    /// @notice Places a bid on an active auction.
    /// @param _auctionId ID of the auction to bid on.
    function placeBid(uint _auctionId) external payable auctionIsActive(_auctionId) nonReentrant {
        Auction storage auction = auctions[_auctionId];
        require(msg.value > auction.currentBid, "Bid must be higher than the current bid");

        if (auction.currentBidder != address(0)) {
            payable(auction.currentBidder).transfer(auction.currentBid);
        }

        auction.currentBid = msg.value;
        auction.currentBidder = msg.sender;
        emit NewBid(_auctionId, msg.sender, msg.value);
    }

    /// @notice Ends an auction and transfers the item to the highest bidder.
    /// @param _auctionId ID of the auction to end.
    function endAuction(uint _auctionId) external nonReentrant {
        Auction storage auction = auctions[_auctionId];
        require(auction.isActive, "Auction is not active");
        require(block.timestamp > auction.endTime, "Auction is still ongoing");

        auction.isActive = false;
        Item storage item = items[auction.itemId];

        if (auction.currentBidder != address(0)) {
            uint fee = (auction.currentBid * FEE_PERCENTAGE) / 100;
            uint sellerAmount = auction.currentBid - fee;

            item.owner = auction.currentBidder;
            item.isSold = true;
            item.seller.transfer(sellerAmount);
            payable(owner).transfer(fee);

            emit AuctionEnded(_auctionId, auction.itemId, auction.currentBidder, auction.currentBid);
        }
    }
}
