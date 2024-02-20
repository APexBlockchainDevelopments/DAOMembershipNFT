// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {MembershipNFT} from "./MembershipNFT.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

contract DAO {

   //errors
   error Already_A_Member();
   error Not_A_Member();

   //Type Declarations
   using PriceConverter for uint256;

   //State Variables
   uint256 public constant MINIMUM_USD = 1000 ** 18;
   
   
   uint256 private i_membershipFeeInUSD;
   address private i_owner;

   uint256 private membershipCount;

   mapping (address => bool) private membershipStatus;
   mapping(address => uint256) private memberToTokenId;
   
   MembershipNFT private membershipNFTContract;
   AggregatorV3Interface private s_priceFeed;


   //events
   event MemberJoined(address member, uint256 memberCount);
   event MemberLeft(address formerMember, uint256 memberCount);   

   constructor(address _owner, address priceFeed) {
      if(_owner == address(0)) {revert();}  //busted!
      s_priceFeed = AggregatorV3Interface(priceFeed);
      i_owner = _owner;
      membershipNFTContract = new MembershipNFT("", ""); //We will fill these in later
   }

   function joinDAO() public payable{
      //check if they are not already a member
      require(getMemberStatus(msg.sender) == false, "You are already a member!");
      //get price and check if it's enough
      require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
      //add them to the dao
      membershipStatus[msg.sender] == true;
      //update membership list
      membershipCount++;
      //mint them a new NFT
      uint256 tokenId = membershipNFTContract.mintNFT(msg.sender);
      //update the members to tokens mapping
      memberToTokenId[msg.sender] = tokenId;
      //emit event
      emit MemberJoined(msg.sender, membershipCount);
   }

   function leaveDAO() public {
      //check if they are a member
      require(getMemberStatus(msg.sender) == true, "You are not a member!");
      //change NFT
      membershipNFTContract.flipNFT(memberToTokenId[msg.sender]);
      //update membership list
      membershipStatus[msg.sender] == false;
      //send funds back to them
      uint256 contractBalance = address(this).balance;
      uint256 shareAmount = contractBalance / membershipCount;
      membershipCount--;
      (bool success,) = msg.sender.call{value: shareAmount}("");
      require(success, "Error");
      //emit event
      emit MemberLeft(msg.sender, membershipCount);
   }

   function getMembershipPriceInETH() public view returns(uint256) {
      (, int256 answer, , , ) = s_priceFeed.latestRoundData();
      // ETH/USD rate in 18 digit
      return uint256(answer * 10000000000);
   }

   function getMemebershipFeeUSD() public pure returns(uint256){
      return MINIMUM_USD / 10**18;
   }

   function getOwner() public view returns(address){
      return i_owner;
   }

   function getNumberOfActiveMembers() external view returns(uint256){
      return membershipCount;
   }

   function getMemberStatus(address _member) public view returns(bool){
      return membershipStatus[_member];
   }
   
   function getMemberTokenId(address _member) external view returns(uint256){
      //what about zero?
      return memberToTokenId[_member];
   }

   function getNFTContractAddress() external view returns(address){
      return address(membershipNFTContract);
   }

   function getPriceFeedAddress() external view returns(address){
      return address(s_priceFeed);
   }
}