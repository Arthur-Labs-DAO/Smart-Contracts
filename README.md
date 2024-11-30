
# Introduction

# Contracts
1. Commerce - The most thorough and up to date contract library Arthur Labs is building. This is an seller to customer contract factory that retrieves the sell product form inputs. There is additionally a customer purchase agreement factory, and a payment proxy that holds the payment until the shipping receipt is provided. Further work necessary.
2. Service - Similar to the contract architecture, there is a service provider smart contract that retrieves the service information from the form inputs, and generated through the ServiceContractFactory.sol, which initiates a ServiceContract.sol. When there is a buyer, a new contract is generated from the PurchaseContractFactory.sol, which initiates a PurchaseContract.sol, with the required information for the service worker to fulfill their work. Additionally a payment proxy is generated through a factory and holds the payment until the service work is agreed to be satisfactory.
3. Delivery - End to end delivery contracts 

## Limitations
1. Currently there is unknown limitations to the legality and litigation found inside of these smart contracts. The applications that utilize this smart contract infrastructure needs to add clear terms and conditions, policies and measurements to enforce the legality and safety of the application.

## Considerations
1. Arthur Labs intends to wrap a juring mechanism around the PaymentProxy.sol so that the smart contract withholds the payment amount to the length of which the seller and buyer agrees, in any case of litigation or concerns, a juring protocol (Kleros, currently) can be incentivized to authorize the winning party in case of dispute.
2. Validator oracles should be considered when implementing a delivery or service contract. 


# Architecture 

```plantuml

actor Seller
actor Buyer
entity SellContract_Factory
entity SellContract
entity PurchaseContract_Factory
entity PurchaseContract
entity PaymentProxy_Factory
entity PaymentProxy

Seller -> SellContract_Factory: Provides product
SellContract_Factory -> SellContract: Generates contract
Buyer -> PurchaseContract_Factory: Provides location
PurchaseContract_Factory -> PurchaseContract: Generates contract
PurchaseContract -> PaymentProxy_Factory: Generates contract 
PaymentProxy_Factory -> PaymentProxy: Generates invoice
PaymentProxy -> SellContract: Data reference
PaymentProxy -> PurchaseContract: Data reference
Buyer -> PaymentProxy: Pays total price
Seller -> Buyer: Ships
Seller -> PaymentProxy: Uploads shipping receipt 
PaymentProxy -> Seller: Payment to Seller




```
