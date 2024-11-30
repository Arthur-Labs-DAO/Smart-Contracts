// SPDX-License-Identifier: APACHE 2.0
pragma solidity 0.8.26;

import "./PaymentProxy.sol";
import "./SellContract.sol";

contract PaymentProxyFactory {
    mapping(address => address) public purchaseToProxy;
    mapping(address => address[]) public buyerProxies;
    mapping(address => address[]) public sellerProxies;

    event ProxyDeployed(address indexed purchaseContract, address proxy, uint256 amount);

    function createPaymentProxy(
        SellContract _sellContract,
        string memory _name,
        string memory _deliveryAddress,
        string memory _customInstructions,
        string memory _additionalNotes,
        uint256 _quantity,
        uint256[] memory _selectedUpchargeIndices,
        uint256 _shippingCost,
        address _buyer
    ) external payable returns (PaymentProxy) {
        PaymentProxy proxy = new PaymentProxy{value: msg.value}(
            _sellContract,
            _name,
            _deliveryAddress,
            _customInstructions,
            _additionalNotes,
            _quantity,
            _selectedUpchargeIndices,
            _shippingCost,
            _buyer
        );

        purchaseToProxy[msg.sender] = address(proxy);
        buyerProxies[_buyer].push(address(proxy));
        sellerProxies[_sellContract.owner()].push(address(proxy));

        emit ProxyDeployed(msg.sender, address(proxy), msg.value);
        return proxy;
    }

    function getProxyForPurchase(address purchaseContract) external view returns (address) {
        return purchaseToProxy[purchaseContract];
    }

    function getBuyerProxies(address buyer) external view returns (address[] memory) {
        return buyerProxies[buyer];
    }

    function getSellerProxies(address seller) external view returns (address[] memory) {
        return sellerProxies[seller];
    }
}
