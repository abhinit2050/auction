//SPDX-License-Identifier: GPL -3.0

pragma solidity >=0.5.0 <0.9.0;

contract Auction{
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfshash;
    enum State {Started, Running, Ended, Cancelled}
    State public auctionState;

    uint public highhestBindingBid;
    address payable public highestBidder;
    mapping(address => uint) public bids;
    uint bidIncrement;

    constructor(){
        owner = payable(msg.sender);
        auctionState = State.Running;
        startBlock = block.number;
        endBlock = block.number + 4; //each block takes about 15 seconds. So 40,320 new blocks in a week - the auction duration
        ipfshash = "";
        bidIncrement = 1000000000000000000;
    }
    modifier notOwner(){
        require(msg.sender != owner);
        _;
    }

    modifier afterStart(){
        require(block.number >= startBlock);
        _;
    }

    modifier beforeEnd(){
        require(block.number <= endBlock);
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    function min(uint a, uint b) pure internal returns (uint){
        if(a<b){
            return a;
        }
        else
        return b;
    }

    function cancelAuction() public onlyOwner{
        auctionState = State.Cancelled;
    }

    function placeBid() public payable notOwner afterStart beforeEnd{
        require(auctionState == State.Running);
        require(msg.value >= 100);

        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highhestBindingBid);
        bids[msg.sender] = currentBid;

        if(currentBid <= bids[highestBidder]) {
            highhestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        } else{
            highhestBindingBid = min(currentBid, bids[highestBidder]+bidIncrement);
            highestBidder = payable (msg.sender);
        }
    }

    function finalizeAuction() public {
       require(auctionState == State.Cancelled || block.number> endBlock);
       require(msg.sender == owner || bids[msg.sender] > 0);

       address payable recipient;
       uint value;

       if(auctionState == State.Cancelled) {
           recipient = payable(msg.sender);
           value = bids[msg.sender];
       } else {
           if(msg.sender == owner){
               recipient = owner;
               value = highhestBindingBid;
           } else {
               if(msg.sender == highestBidder) {
                   recipient = highestBidder;
                   value = bids[highestBidder] - highhestBindingBid;
               } else {
                   recipient = payable(msg.sender);
                   value = bids[msg.sender];
               }
           }
       }
       recipient.transfer(value);
    }
} 