// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/* 
    Coin Contracts that will create the 
    AliceCoin and BobCoin tokens 
    Both tokens are created with a supply
    Both token contracts are automatically approved to spend tokens
    */


contract AliceCoin is ERC20 {
    constructor() ERC20("AliceCoin", "ALI") {
        _mint(msg.sender, 1000000);
        _approve(msg.sender, address(this), 250000);
        _approve(msg.sender, msg.sender, 250000);
    } 
}

contract BobCoin is ERC20{
    constructor() ERC20("BobCoin", "BOB"){
        _mint(msg.sender, 1000000);
        _approve(msg.sender, address(this), 250000);
        _approve(msg.sender, msg.sender, 250000);
    }
}
/*
    Reminder for developer
    Remix:
    _tokenAddress == Address of tokens
    msg.sender == address of contract
    owner == address of contract 0x5B3
    spender == address of account 0xAb8
    recipient == address of account 0xAb8

    On AliceCoin contract:
    Supply on account 1 (0x5B3) --

    (Make sure account is set to 0x5B3)
    
    transfer() to other accounts (0xAb8 or 0x4B2)
    approve() to the same accounts
    use transferFrom() between any of the accounts, make sure that its greater than <  allowance && < balanceOf 
    
    
    On AtomicSwap contract:
    On AliceCoin, approve smartcontract(address) to spend tokens

    Approve -- Allowance -- transferFrom
    supply -- balanceOf -- transfer



*/



contract AtomicSwap{
    AliceCoin public tokenA;
    BobCoin public tokenB;
    string public secret = "Caroline";
    // User who should recieve the contract
    address payable recipient;
    // Owner of the coin 
    address payable  Owner;
    // Address of the token
    address tokenAddress;
    // The amount of the tokens swapped 
    uint256 amount;
    //uint256 amount; // An amount of the token wanting to be transferred
    // Time stated for Swap to be executed
    uint256 timelock;
    // Cryptographic secret key 
    bytes32 Hashlock = 0x604d222bc5d2fbea27c4060354248e0e5f928c893d6f496d7cd9fb0749e2401d;
    // Secret key 
    //string public secret = "djkcoeuxhjkdf";
    // Boolean to check if the owner has been refunded 
    bool refunded; 
    // Boolean to check if the token has been claimed
    bool claimed;

     // A constructor for the smart contract
     constructor(address _addressAliceCoin, address _addressBobCoin) payable {
        tokenA = AliceCoin(_addressAliceCoin);
        tokenB = BobCoin(_addressBobCoin);
     }
     

    mapping(address => mapping(address => uint256)) private _allowances;
    //mapping(address => Swap) public swaps;


    event NewAtomicSwap(
        address swapId,
        address payable Owner,
        address payable recipient,
        address tokenAddress,
        uint256 amount,
        bytes32 Hashlock,
        uint256 timelock
    );
    event Claimed(
        bool claimed
    );
    event Refunded(
        bool refunded
    );

    // Modifiers 

    /* Check the account has a funded allowance  */

    modifier checkAllowance(address _token, address _Owner, uint256 _amount){
        require(_amount > 0, "Token amount must be greater than 0");
        require(tokenA.allowance(_Owner, address(this)) >= _amount, "Allowance must be greater than 0");
        _;
    }

    /* Make sure the timelock is set in the future  */

    modifier futureTimelock(uint256 _time){
        require(_time > block.timestamp, "timelock has to be set in the future");
        _;
    }

    /* Requirements in place for claiming the token  */

    modifier claimable() {
            require(claimed == false, "already claimed");
            require(refunded == false, "already refunded");
            _;
    }


    /* 
    Create a modifier to check if the secret (in hash form) 
    matches the hashlock
       */


    modifier matchingHashlocks(string memory _secret){
        require(Hashlock == keccak256(abi.encodePacked(_secret)),
            "incorrect hashlock"
        );
        _;
    }

    /* Modifier check for refund funciton */
    /*  */

    modifier refundable() {
        require(Inf.o == msg.sender, "Only the sender of this coin can refund");
        require(refunded == false, "Already refunded"); // Check coin has not already been funded
        require(claimed == false, "Already claimed"); // Check coin is not claimed already
        require(Inf.t <= block.timestamp, "Timelock not yet passed"); // Check time has not expired
        _;
    }

    /* A struct made to store information entered into the newSwap function s */


    struct SwapInfo{
            address payable r;
            address payable o;
            bytes32 h;
            uint256 t;
            uint256 a;
        }
    SwapInfo Inf; // Instantiate the struct


    /* function to initiate a swap  */

    function newSwap(
        address payable _recipient, 
        bytes32 _Hashlock,
        uint256 _timelock,
        address _tokenAddress,
        uint256 _amount
        )
    public  // Visibility
    payable
    checkAllowance(_tokenAddress, msg.sender, _amount)
    futureTimelock(_timelock)
    returns(address swapId)
    {

        /* Store input information to be used later  */
        Inf = SwapInfo(_recipient, payable(msg.sender), _Hashlock, _timelock, _amount);

        if(haveContract(swapId))
            revert("Contract exists");
        
        _timelock = timelock;
        tokenB.approve(address(this), 250000);

        emit NewAtomicSwap(
            swapId,
            payable(_recipient),
            _recipient,
            _tokenAddress,
            _amount,
            _Hashlock,
            _timelock
        );     
    }

    

    function fund(uint256 _amount) external payable {
        // Token is sent from account caller --> AtomicSwap contract
        // AtomicSwap contract now holds some tokenA
        tokenA.transferFrom(msg.sender, address(this), _amount);
    }

    function contractBalance() view public returns(uint256){
        return tokenA.balanceOf(address(this));
    }

    /* Function for recipient to claim token */
    function claim(string memory _secret) public payable 
    claimable() 
    matchingHashlocks(_secret) 
    
    returns(bool)
    
    {
        secret = _secret;
        claimed = true;
        
        tokenA.transfer(Inf.r, Inf.a);
        
        tokenB.transferFrom(msg.sender, address(this), 250000);
        tokenB.transfer(Inf.o, Inf.a);
        
        emit Claimed(claimed);
        return true;
    }

    function refund() external 
    
    refundable() 
    returns(bool) {   
       
       refunded = true;
       tokenA.transfer(Inf.o, Inf.a);
       emit Refunded(refunded);
       return true;
    }
    
    
    function ALIbalance() external view returns (uint256) {
        // Check balance of tokenA (AliceCoin)
        return tokenA.balanceOf(address(this));
    }
    
    function BOBbalance() external view returns (uint256) {
        // Check balance of tokenB (BobCoin)
        return tokenB.balanceOf(address(this));
    }

    function approve(uint256 _amount) external  {
       
        tokenA.approve(msg.sender, _amount);
    }


    function haveContract(address _swapId) internal view returns (bool available){
        available = Owner != address(0);
    }

    function getHashlock() public pure returns (bytes32){
        bytes32 ash = 0x604d222bc5d2fbea27c4060354248e0e5f928c893d6f496d7cd9fb0749e2401d;
        return ash;
    }

    /* Returns current time in Unix Epoch seconds */

    function getTimestamp() public view returns(uint256) {
        uint256 t = block.timestamp;
        return t;
    }

    /* Returns the timestamp + extra 300 seconds  */

    function getTimelock() public view returns(uint256){
        uint256 tm  = block.timestamp + 300; // Five minutes
        return tm;
    }


}

contract Hash {
    function calculateHash(string memory _key) external pure  returns(bytes32){
        return keccak256(abi.encodePacked(_key));
    }
}