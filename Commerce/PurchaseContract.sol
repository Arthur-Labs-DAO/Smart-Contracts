// SPDX-License-Identifier: APACHE 2.0
pragma solidity 0.8.26;

import "./SellContract.sol";
import "./PaymentProxy.sol";

contract PurchaseContract {
    error IncorrectPaymentAmount(uint256 expected, uint256 received);

    SellContract public immutable sellContract;
    PaymentProxy public paymentProxy;
    address payable public immutable buyer;
    string public name;
    string public deliveryAddress;
    string public customInstructions;
    string public additionalNotes;
    uint256 public immutable quantity;
    bool public isPurchased;
    bool private locked;
    uint256[] public selectedUpchargeIndices;
    uint256 public immutable shippingCost;

    event ProxyCreated(address proxyAddress, uint256 value);
    event PurchaseSubmitted(
        address indexed buyer,
        string name,
        uint256 value,
        uint256 quantity,
        uint256[] selectedUpcharges,
        address paymentProxy
    );

    constructor(
        address _sellContract,
        string memory _name,
        string memory _deliveryAddress,
        string memory _customInstructions,
        string memory _additionalNotes,
        uint256 _quantity,
        uint256[] memory _selectedUpchargeIndices,
        uint256 _shippingCost
    ) payable {
        require(_sellContract != address(0), "Invalid sell contract address");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_deliveryAddress).length > 0, "Delivery address cannot be empty");
        require(_quantity > 0, "Quantity must be greater than 0");

        sellContract = SellContract(_sellContract);
        buyer = payable(msg.sender);
        name = _name;
        deliveryAddress = _deliveryAddress;
        customInstructions = _customInstructions;
        additionalNotes = _additionalNotes;
        quantity = _quantity;
        selectedUpchargeIndices = _selectedUpchargeIndices;
        shippingCost = _shippingCost;

        uint256 itemsTotal = calculateItemsTotal(_quantity, _selectedUpchargeIndices);
        uint256 totalPrice = itemsTotal + _shippingCost;

        if (msg.value != totalPrice) {
            revert IncorrectPaymentAmount(totalPrice, msg.value);
        }

        bytes memory paymentProxyBytecode = type(PaymentProxy).creationCode;
        bytes memory constructorArgs = abi.encode(
            sellContract,
            _name,
            _deliveryAddress,
            _customInstructions,
            _additionalNotes,
            _quantity,
            _selectedUpchargeIndices,
            msg.sender
        );

        bytes memory deploymentBytecode = abi.encodePacked(
            paymentProxyBytecode,
            constructorArgs
        );

        address payable proxyAddress;
        assembly {
            proxyAddress := create2(
                callvalue(),
                add(deploymentBytecode, 0x20),
                mload(deploymentBytecode),
                0
            )
        }

        require(address(proxyAddress) != address(0), "Proxy deployment failed");
        paymentProxy = PaymentProxy(proxyAddress);

        isPurchased = true;

        sellContract.storePurchaseInfo(
            buyer,
            deliveryAddress,
            customInstructions,
            additionalNotes,
            selectedUpchargeIndices
        );

        emit ProxyCreated(proxyAddress, msg.value);
        emit PurchaseSubmitted(
            buyer,
            name,
            msg.value,
            quantity,
            _selectedUpchargeIndices,
            address(proxyAddress)
        );
    }

    function calculateItemsTotal(uint256 _quantity, uint256[] memory _indices)
        public
        view
        returns (uint256)
    {
        uint256 basePrice = sellContract.price() * _quantity;
        uint256 upchargeAmount = 0;

        for(uint256 i = 0; i < _indices.length; i++) {
            (,uint256 value,bool isActive) = sellContract.upcharges(_indices[i]);
            if(isActive) {
                upchargeAmount += value;
            }
        }

        return basePrice + upchargeAmount;
    }

    function calculateTotalPrice(uint256 _quantity, uint256[] memory _indices, uint256 _shippingCost)
        public
        view
        returns (uint256)
    {
        uint256 itemsTotal = calculateItemsTotal(_quantity, _indices);
        return itemsTotal + _shippingCost;
    }

    function getPaymentProxy() public view returns (address) {
        return address(paymentProxy);
    }

    function isShippingProofProvided() public view returns (bool) {
        return paymentProxy.isShipped();
    }

    function getShippingDetails() public view returns (
        string memory trackingNumber,
        string memory carrier,
        uint256 timestamp,
        string memory additionalInfo,
        bool shipped
    ) {
        return paymentProxy.getShippingDetails();
    }

    function isPaymentReleased() public view returns (bool) {
        return paymentProxy.isReleased();
    }
}
