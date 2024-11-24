// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Croakmarket
/// @notice A simple marketplace contract for listing, purchasing, and transferring items
/// @dev This contract manages items, their ownership, and transactions
contract Croakmarket {
    /// @notice Structure to represent an item in the marketplace
    /// @dev Each item has a unique ID, name, price, seller, owner, and sale status
    struct Item {
        uint id;
        string name;
        uint price;
        address payable seller;
        address owner;
        bool isSold;
    }

    /// @notice Total number of items listed in the marketplace
    uint public itemCount = 0;

    /// @notice Mapping of item IDs to Item structs
    mapping(uint => Item) public items;

    /// @notice Mapping of owner addresses to arrays of owned item IDs
    mapping(address => uint[]) public ownedItems;

    /// @notice Lists a new item in the marketplace
    /// @param _name The name of the item
    /// @param _price The price of the item in wei
    /// @dev Increments itemCount and adds the new item to the items mapping
    function listItem(string memory _name, uint _price) public {
        require(_price > 0, "Price must be greater than zero");

        itemCount++;
        items[itemCount] = Item(itemCount, _name, _price, payable(msg.sender), msg.sender, false);
        ownedItems[msg.sender].push(itemCount);
    }

    /// @notice Allows a user to purchase an item
    /// @param _id The ID of the item to purchase
    /// @dev Transfers the item's price to the seller and updates ownership
    function purchaseItem(uint _id) public payable {
        Item storage item = items[_id];
        require(_id > 0 && _id <= itemCount, "Item does not exist");
        require(msg.value == item.price, "Incorrect price");
        require(!item.isSold, "Item already sold");
        require(msg.sender != item.seller, "Seller cannot buy their own item");

        item.isSold = true;
        item.seller.transfer(msg.value);

        // Transfer ownership
        _transferOwnership(_id, item.seller, msg.sender);
    }

    /// @notice Internal function to transfer ownership of an item
    /// @param _id The ID of the item
    /// @param _from The current owner's address
    /// @param _to The new owner's address
    /// @dev Updates the item's owner and adjusts the ownedItems mappings
    function _transferOwnership(uint _id, address _from, address _to) internal {
        Item storage item = items[_id];
        item.owner = _to;

        // Remove item from the previous owner's list
        uint[] storage fromItems = ownedItems[_from];
        for (uint i = 0; i < fromItems.length; i++) {
            if (fromItems[i] == _id) {
                fromItems[i] = fromItems[fromItems.length - 1];
                fromItems.pop();
                break;
            }
        }

        // Add item to the new owner's list
        ownedItems[_to].push(_id);
    }

    /// @notice Allows the owner to transfer an item to another address
    /// @param _id The ID of the item to transfer
    /// @param _to The address of the recipient
    /// @dev Calls the internal _transferOwnership function
    function transferItem(uint _id, address _to) public {
        Item storage item = items[_id];
        require(_id > 0 && _id <= itemCount, "Item does not exist");
        require(msg.sender == item.owner, "You do not own this item");

        _transferOwnership(_id, msg.sender, _to);
    }

    /// @notice Retrieves all item IDs owned by a specific address
    /// @param _owner The address of the owner
    /// @return An array of item IDs owned by the specified address
    function getItemsByOwner(address _owner) public view returns (uint[] memory) {
        return ownedItems[_owner];
    }
}