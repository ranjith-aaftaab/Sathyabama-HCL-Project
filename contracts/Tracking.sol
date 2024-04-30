// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Tracking {
    enum ShipmentStatus { Pending, InTransit, Delivered }

    struct Shipment {
        address sender;
        address receiver;
        uint256 pickUpTime;
        uint256 deliveryTime;
        uint256 distance;
        uint256 price; // Added price field
        ShipmentStatus status;
        bool isPaid;
    }

    mapping(address => Shipment[]) public shipments;
    uint256 public shipmentCount;

    struct TypeShipment {
        address sender;
        address receiver;
        uint256 pickUpTime;
        uint256 deliveryTime;
        uint256 distance;
        uint256 price;
        ShipmentStatus status;
        bool isPaid;
    }

    TypeShipment[] public typeShipments;

    event ShipmentCreated(address indexed sender, address indexed receiver, uint256 pickUpTime, uint256 distance, uint256 price);
    event ShipmentInTransit(address indexed sender, address indexed receiver, uint256 deliveryTime);
    event ShipmentDelivered(address indexed sender, address indexed receiver, uint256 deliveryTime);
    event ShipmentPaid(address indexed sender, address indexed receiver, uint256 amount);

    constructor() {
        shipmentCount = 0;
    }

    function createShipment(address _receiver, uint256 _pickUpTime, uint256 _distance, uint256 _price) public payable {
        require(msg.value == _price, "Payment must match the price");

        Shipment memory newShipment = Shipment(msg.sender, _receiver, _pickUpTime, 0, _distance, _price, ShipmentStatus.Pending, false); // Updated to include price
        shipments[msg.sender].push(newShipment);
        shipmentCount++;

        typeShipments.push(TypeShipment(msg.sender, _receiver, _pickUpTime, 0, _distance, _price, ShipmentStatus.Pending, false));

        emit ShipmentCreated(msg.sender, _receiver, _pickUpTime, _distance, _price);
    }

    function startShipment(address _sender, address _receiver, uint256 _index) public {
        Shipment storage shipment = shipments[_sender][_index];
        TypeShipment storage typeShipment = typeShipments[_index];

        require(shipment.receiver == _receiver, "Invalid receiver");
        require(shipment.status == ShipmentStatus.Pending, "Shipment already in transit");

        shipment.status = ShipmentStatus.InTransit;
        typeShipment.status = ShipmentStatus.InTransit;

        emit ShipmentInTransit(_sender, _receiver, shipment.pickUpTime);
    }

    function completeShipment(address _sender, address _receiver, uint256 _index) public {
        Shipment storage shipment = shipments[_sender][_index];
        TypeShipment storage typeShipment = typeShipments[_index];

        require(shipment.receiver == _receiver, "Invalid receiver");
        require(shipment.status == ShipmentStatus.InTransit, "Shipment not in transit");
        require(!shipment.isPaid, "Shipment already paid");

        shipment.status = ShipmentStatus.Delivered;
        typeShipment.status = ShipmentStatus.Delivered;
        typeShipment.deliveryTime = block.timestamp;
        shipment.deliveryTime = block.timestamp;

        uint256 amount = shipment.price;
        payable(shipment.sender).transfer(amount);

        shipment.isPaid = true;
        typeShipment.isPaid = true;

        emit ShipmentDelivered(_sender, _receiver, shipment.deliveryTime);
        emit ShipmentPaid(_sender, _receiver, amount);
    }

    function getShipment(address _sender, uint256 _index) public view returns (address, address, uint256, uint256, uint256, ShipmentStatus, bool) {
        Shipment memory shipment = shipments[_sender][_index];
        return (shipment.sender, shipment.receiver, shipment.pickUpTime, shipment.deliveryTime, shipment.distance, shipment.status, shipment.isPaid);
    }

    function getShipmentCount(address _sender) public view returns (uint256) {
        return shipments[_sender].length;
    }

    function getAllTransactions() public view returns (TypeShipment[] memory) {
        return typeShipments;
    }
}
