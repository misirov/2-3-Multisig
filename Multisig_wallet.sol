// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txId);
    event Confirm(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public required;
    

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    // mapping from tx id => owner => bool
    mapping(uint => mapping(address => bool)) public confirmations;
    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txId) {
        require(_txId < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txId) {
        require(!transactions[_txId].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txId) {
        require(!confirmations[_txId][msg.sender], "tx already confirmed");
        _;
    }

    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "owners required");
        require(
            _required > 0 && _required <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
    }
    
    
    function submit(address _to, uint _value, bytes calldata _data) external onlyOwner{

        uint txId = transactions.length;
        
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed:false
        }));
        
        emit Submit(txId);
        
    }


    function confirm(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) notConfirmed(_txId){
        confirmations[_txId][msg.sender] = true;
        emit Confirm(msg.sender, _txId);
    }
    
    
    function getConfirmationCount(uint _txId) private view returns(uint) {
        uint n = 0;
        for(uint256 i = 0; i < owners.length; i++){
            address ow = owners[i];
            if(confirmations[_txId][ow] == true){
                n++;
            }
        }
        
        return n;
    }

    
    function execute(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId){
        Transaction storage transaction = transactions[_txId];
        
        require(getConfirmationCount(_txId) >= required, "Not enough confirmations");
        
        transaction.executed = true;
        
        (bool success, ) = transaction.to.call{value:transaction.value}(transaction.data);
        require(success, "transaction failed");
        emit Execute(_txId);
    }


    function revoke(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId){
        require(confirmations[_txId][msg.sender], "tx not confirmed");
        confirmations[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }

    receive() external payable {}
    
}




