// SPDX-License-Identifier: APACHE 2.0
pragma solidity 0.8.26;

import "./SellContract.sol";

// Payment Proxy Contract
contract PaymentProxy {
    struct PurchaseDetails {
        address payable buyer;
        string name;
        string deliveryAddress;
        string customInstructions;
        string additionalNotes;
        uint256 quantity;
        uint256[] selectedUpchargeIndices;
        uint256 shippingCost;
        uint256 paymentAmount;
        bool isReleased;
    }

    struct ShippingDetails {
        string trackingNumber;
        string carrier;
        uint256 timestamp;
        string additionalInfo;
    }

    SellContract public sellContract;
    ShippingDetails public shippingDetails;
    bool public isShipped;
    bool public isReleased;
    bool private locked;

    PurchaseDetails public purchaseDetails;

    event PaymentReceived(address buyer, uint256 amount);
    event ShippingProofProvided(string trackingNumber, string carrier, uint256 timestamp);
    event PaymentReleased(address seller, uint256 amount);

    modifier nonReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }

    modifier onlySellContractOwner() {
        require(msg.sender == sellContract.owner(), "Only sell contract owner can call this");
        _;
    }

    modifier onlyBuyer() {
        require(msg.sender == purchaseDetails.buyer, "Only buyer can call this");
        _;
    }

    receive() external payable {
        emit PaymentReceived(msg.sender, msg.value);
    }

    fallback() external payable {
        emit PaymentReceived(msg.sender, msg.value);
    }

    constructor(
        SellContract _sellContract,
        string memory _name,
        string memory _deliveryAddress,
        string memory _customInstructions,
        string memory _additionalNotes,
        uint256 _quantity,
        uint256[] memory _selectedUpchargeIndices,
        uint256 _shippingCost,
        address _buyer
    ) payable {
        require(address(_sellContract) != address(0), "Invalid sell contract");
        require(_buyer != address(0), "Invalid buyer address");

        sellContract = _sellContract;

        purchaseDetails = PurchaseDetails({
            buyer: payable(_buyer),
            name: _name,
            deliveryAddress: _deliveryAddress,
            customInstructions: _customInstructions,
            additionalNotes: _additionalNotes,
            quantity: _quantity,
            selectedUpchargeIndices: _selectedUpchargeIndices,
            shippingCost: _shippingCost,
            paymentAmount: msg.value,
            isReleased: false
        });

        if(msg.value > 0) {
            emit PaymentReceived(_buyer, msg.value);
        }
    }

    function provideShippingProof(
        string memory _trackingNumber,
        string memory _carrier,
        string memory _additionalInfo
    ) external onlySellContractOwner {
        require(!isShipped, "Shipping proof already provided");
        require(bytes(_trackingNumber).length > 0, "Tracking number cannot be empty");
        require(bytes(_carrier).length > 0, "Carrier cannot be empty");

        shippingDetails = ShippingDetails({
            trackingNumber: _trackingNumber,
            carrier: _carrier,
            timestamp: block.timestamp,
            additionalInfo: _additionalInfo
        });

        isShipped = true;

        emit ShippingProofProvided(_trackingNumber, _carrier, block.timestamp);
    }

    function releasePayment() external nonReentrant {
        require(isShipped, "Shipping proof not provided yet");
        require(!isReleased, "Payment already released");
        require(
            msg.sender == purchaseDetails.buyer ||
            msg.sender == sellContract.owner(),
            "Only buyer or seller can release payment"
        );

        purchaseDetails.isReleased = true;
        isReleased = true;

        address payable seller = payable(sellContract.owner());
        (bool success, ) = seller.call{value: address(this).balance}("");
        require(success, "Payment release failed");

        emit PaymentReleased(seller, address(this).balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getBuyer() public view returns (address) {
        return purchaseDetails.buyer;
    }

    function getDeliveryDetails() public view returns (
        string memory name,
        string memory deliveryAddress,
        string memory customInstructions,
        string memory additionalNotes
    ) {
        return (
            purchaseDetails.name,
            purchaseDetails.deliveryAddress,
            purchaseDetails.customInstructions,
            purchaseDetails.additionalNotes
        );
    }

    function getOrderDetails() public view returns (
        uint256 quantity,
        uint256[] memory selectedUpcharges,
        uint256 paymentAmount
    ) {
        return (
            purchaseDetails.quantity,
            purchaseDetails.selectedUpchargeIndices,
            purchaseDetails.paymentAmount
        );
    }

    function getShippingDetails() public view returns (
        string memory trackingNumber,
        string memory carrier,
        uint256 timestamp,
        string memory additionalInfo,
        bool shipped
    ) {
        return (
            shippingDetails.trackingNumber,
            shippingDetails.carrier,
            shippingDetails.timestamp,
            shippingDetails.additionalInfo,
            isShipped
        );
    }
}
