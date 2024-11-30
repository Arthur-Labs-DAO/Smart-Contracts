// SPDX-License-Identifier: APACHE 2.0
pragma solidity 0.8.26;

import "./SellContract.sol";

contract SellContractFactory {
    address[] public sellContracts;
    mapping(address => address[]) public ownerToContracts;

    event SellContractCreated(
        address indexed newContractAddress,
        address indexed owner,
        string title
    );

    function createSellContract(
        string memory _title,
        string memory _description,
        string memory _image,
        string memory _location,
        SellContract.ShippingMethod[] memory _shippingMethods,
        SellContract.Upcharge[] memory _upcharges,
        uint256 _price,
        uint256 _quantity,
        uint256 _timeValidity,
        string memory _listingID
    ) public returns (address) {
        require(_shippingMethods.length > 0, "Must include at least one shipping method");

        SellContract newContract = new SellContract(
            msg.sender,
            _title,
            _description,
            _image,
            _location,
            _shippingMethods,
            _upcharges,
            _price,
            _quantity,
            _timeValidity,
            _listingID
        );

        sellContracts.push(address(newContract));
        ownerToContracts[msg.sender].push(address(newContract));

        emit SellContractCreated(address(newContract), msg.sender, _title);
        return address(newContract);
    }

    function getSellContractsCount() public view returns (uint256) {
        return sellContracts.length;
    }

    function getSellContractAddress(uint256 index) public view returns (address) {
        require(index < sellContracts.length, "Invalid contract index");
        return sellContracts[index];
    }

    function getOwnerContracts(address owner) public view returns (address[] memory) {
        return ownerToContracts[owner];
    }

    function getAllSellContracts() public view returns (address[] memory) {
        return sellContracts;
    }
}
