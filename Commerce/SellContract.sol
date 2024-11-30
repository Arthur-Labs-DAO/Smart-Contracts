// SPDX-License-Identifier: APACHE 2.0
pragma solidity 0.8.26;

contract SellContract {
   struct ShippingMethod {
       string name;
       uint256 value;
       bool isActive;
   }

   struct Upcharge {
       string name;
       uint256 value;
       bool isActive;
   }

   struct PurchaseInfo {
       string deliveryAddress;
       string customInstructions;
       string additionalNotes;
       uint256[] selectedUpcharges;
   }

   address public owner;
   string public title;
   string public description;
   string public image;
   string public location;
   uint256 public price;
   uint256 public quantity;
   uint256 public customerCount;
   uint256 public timeValidity;
   string public listingID;
   bool public isSoldOut;
   bool public isDelivered;

   ShippingMethod[] public shippingMethods;
   Upcharge[] public upcharges;
   mapping(address => PurchaseInfo) private purchaseDetails;

   event ItemPurchased(address indexed buyer, uint256 value, uint256 timestamp);
   event ItemDelivered(address indexed buyer);
   event PurchaseInfoStored(
       address indexed buyer,
       string deliveryAddress,
       string customInstructions,
       string additionalNotes,
       uint256[] selectedUpcharges
   );
   event StatusUpdated(bool isSoldOut, bool isDelivered);

   modifier onlyOwner() {
       require(msg.sender == owner, "Only owner can call this function");
       _;
   }

   constructor(
       address _owner,
       string memory _title,
       string memory _description,
       string memory _image,
       string memory _location,
       ShippingMethod[] memory _shippingMethods,
       Upcharge[] memory _upcharges,
       uint256 _price,
       uint256 _quantity,
       uint256 _timeValidity,
       string memory _listingID
   ) {
       require(_shippingMethods.length > 0, "Must have at least one shipping method");

       owner = _owner;
       title = _title;
       description = _description;
       image = _image;
       location = _location;
       price = _price;
       quantity = _quantity;
       customerCount = 0;
       timeValidity = block.timestamp + _timeValidity;
       listingID = _listingID;
       isSoldOut = false;
       isDelivered = false;

       for(uint i = 0; i < _shippingMethods.length; i++) {
           shippingMethods.push(ShippingMethod({
               name: _shippingMethods[i].name,
               value: _shippingMethods[i].value,
               isActive: true
           }));
       }

       if(_upcharges.length > 0) {
           for(uint i = 0; i < _upcharges.length; i++) {
               upcharges.push(Upcharge({
                   name: _upcharges[i].name,
                   value: _upcharges[i].value,
                   isActive: true
               }));
           }
       }
   }

   function calculateTotalPrice(uint256[] memory indices, uint256 shippingIndex) public view returns (uint256) {
       require(shippingIndex < shippingMethods.length, "Invalid shipping method");
       require(shippingMethods[shippingIndex].isActive, "Shipping method not active");

       uint256 totalPrice = price;

       totalPrice += shippingMethods[shippingIndex].value;

       for(uint256 i = 0; i < indices.length; i++) {
           require(indices[i] < upcharges.length, "Invalid upcharge index");
           if(upcharges[indices[i]].isActive) {
               totalPrice += upcharges[indices[i]].value;
           }
       }

       return totalPrice;
   }

   function storePurchaseInfo(
       address _buyer,
       string memory _deliveryAddress,
       string memory _customInstructions,
       string memory _additionalNotes,
       uint256[] memory _selectedUpcharges
   ) public {
       purchaseDetails[_buyer] = PurchaseInfo({
           deliveryAddress: _deliveryAddress,
           customInstructions: _customInstructions,
           additionalNotes: _additionalNotes,
           selectedUpcharges: _selectedUpcharges
       });

       customerCount++;

       if(customerCount >= quantity) {
           isSoldOut = true;
           emit StatusUpdated(isSoldOut, isDelivered);
       }

       emit ItemPurchased(_buyer, price, block.timestamp);
       emit PurchaseInfoStored(
           _buyer,
           _deliveryAddress,
           _customInstructions,
           _additionalNotes,
           _selectedUpcharges
       );
   }

   function getPurchaseDetails(address _buyer) public view returns (
       string memory deliveryAddress,
       string memory customInstructions,
       string memory additionalNotes,
       uint256[] memory selectedUpcharges
   ) {
       PurchaseInfo memory info = purchaseDetails[_buyer];
       return (
           info.deliveryAddress,
           info.customInstructions,
           info.additionalNotes,
           info.selectedUpcharges
       );
   }

   function getShippingMethods() public view returns (ShippingMethod[] memory) {
       return shippingMethods;
   }

   function getUpcharges() public view returns (Upcharge[] memory) {
       return upcharges;
   }

   function markAsDelivered() public {
       require(!isDelivered, "Already marked as delivered");
       isDelivered = true;
       emit ItemDelivered(msg.sender);
       emit StatusUpdated(isSoldOut, isDelivered);
   }
}
