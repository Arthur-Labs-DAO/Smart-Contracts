// SPDX-License-Identifier: APACHE 2.0
pragma solidity 0.8.26;

import "./PaymentProxyFactory.sol";
import "./PurchaseContract.sol";

error NoValueSent();
error InvalidPriceSent(uint256 expected, uint256 received);

contract PurchaseContractFactory {
    PaymentProxyFactory public immutable proxyFactory;
    address[] private purchaseContracts;
    mapping(address => address[]) private buyerToContracts;

    struct PurchaseRequest {
        address sellContract;
        string name;
        string delivery;
        string instructions;
        string notes;
        uint256 quantity;
        uint256[] upcharges;
        uint256 shipping;
    }

    event PurchaseContractCreated(
        address indexed contractAddress,
        address indexed buyer,
        address indexed proxyAddress,
        uint256 totalPrice
    );

    constructor(address _proxyFactory) {
        proxyFactory = PaymentProxyFactory(_proxyFactory);
    }

    // Preview function for frontend to check prices
    function calculateTotalPrice(
        address _sellContract,
        uint256 _quantity,
        uint256[] calldata _upcharges,
        uint256 _shipping
    ) public view returns (
        uint256 basePrice,
        uint256 upchargesTotal,
        uint256 shippingCost,
        uint256 totalPrice
    ) {
        SellContract sellContract = SellContract(_sellContract);

        basePrice = sellContract.price() * _quantity;
        upchargesTotal = 0;

        for(uint256 i = 0; i < _upcharges.length; i++) {
            (,uint256 value,bool isActive) = sellContract.upcharges(_upcharges[i]);
            if(isActive) {
                upchargesTotal += value * _quantity;
            }
        }

        shippingCost = _shipping;
        totalPrice = basePrice + upchargesTotal + shippingCost;
    }

    function createPurchaseContract(
        PurchaseRequest calldata request
    ) external payable returns (address) {
        if(msg.value == 0) revert NoValueSent();

        // Calculate expected price
        (
            uint256 basePrice,
            uint256 upchargesTotal,
            uint256 shippingCost,
            uint256 totalPrice
        ) = calculateTotalPrice(
            request.sellContract,
            request.quantity,
            request.upcharges,
            request.shipping
        );

        if (msg.value != totalPrice) {
            revert InvalidPriceSent(totalPrice, msg.value);
        }

        PurchaseContract newContract = new PurchaseContract{value: msg.value}(
            request.sellContract,
            request.name,
            request.delivery,
            request.instructions,
            request.notes,
            request.quantity,
            request.upcharges,
            request.shipping
        );

        address contractAddr = address(newContract);
        purchaseContracts.push(contractAddr);
        buyerToContracts[msg.sender].push(contractAddr);

        emit PurchaseContractCreated(
            contractAddr,
            msg.sender,
            newContract.getPaymentProxy(),
            totalPrice
        );

        return contractAddr;
    }

    function getContracts(address buyer) external view returns (uint256 count, address[] memory contracts) {
        contracts = buyerToContracts[buyer];
        count = contracts.length;
    }

    function getContractAt(uint256 index) external view returns (address) {
        return index < purchaseContracts.length ? purchaseContracts[index] : address(0);
    }

    function getContractCount() external view returns (uint256) {
        return purchaseContracts.length;
    }
}
