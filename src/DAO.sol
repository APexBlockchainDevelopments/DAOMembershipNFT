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
   struct Member {   //should build a funciton in NFT contract to receive all info and params 
      address wallet;
      uint256 joinDate;
      uint256 membershipId;
      bool membershipStatus;
   }

   uint256 public constant MINIMUM_USD = 1000e18;
   
   
   uint256 private i_membershipFeeInUSD;
   address private i_owner;

   uint256 private membershipCount;

   mapping (address => Member) private membershipInfomation;  //this will contain all member info into a single mapping
   
   MembershipNFT private membershipNFTContract;
   AggregatorV3Interface private s_priceFeed;


   //events
   event MemberJoined(address member, uint256 memberCount);
   event MemberLeft(address formerMember, uint256 memberCount);   
   event FundsWithdrew(uint256 amount, string reason);

   constructor(address _owner, address priceFeed, string memory activeMemberSvg, string memory formerMemberSvg) {
      if(_owner == address(0)) {revert();}  //busted!
      s_priceFeed = AggregatorV3Interface(priceFeed);
      i_owner = _owner;
      membershipNFTContract = new MembershipNFT(activeMemberSvg, formerMemberSvg); //We will fill these in later
   }

   function joinDAO() public payable{
      //check if they are not already a member
      require(getMemberStatus(msg.sender) == false, "You are already a member!");
      //get price and check if it's enough
      require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
      //only contracts cannot join the dao as a member
      require(!isContract(msg.sender), "Contracts are not allowed to join the dao");
      
      //add them to the dao
      Member memory newMember = Member({
         wallet: msg.sender,
         joinDate : block.timestamp,
         membershipId : membershipCount,
         membershipStatus : true
      });

      membershipInfomation[msg.sender] = newMember;

      //update membership list
      membershipCount++;
      //mint them a new NFT
      uint256 tokenId = membershipNFTContract.mintNFT(msg.sender);

      //emit event
      emit MemberJoined(msg.sender, membershipCount);
   }

   function leaveDAO() public {
      //check if they are a member
      require(getMemberStatus(msg.sender) == true, "You are not a member!");
      //change NFT
      uint256 tokenId = getMemberTokenId(msg.sender);
      membershipNFTContract.updateNFT(tokenId); //should also include member information
      //update membership list
      Member memory leavingMember = membershipInfomation[msg.sender];
      leavingMember.membershipStatus = false;
      membershipInfomation[msg.sender] = leavingMember;

      //send funds back to them
      uint256 contractBalance = address(this).balance;
      uint256 shareAmount = contractBalance / membershipCount;
      membershipCount--;
      (bool success,) = msg.sender.call{value: shareAmount}("");
      require(success, "Error");
      //emit event
      emit MemberLeft(msg.sender, membershipCount);
   }

   function ownerWithdrawFunds(uint256 withdrawAmount, string memory reason) public {
      require(msg.sender == i_owner, "You are not allowed to withdraw funds!");
      require(withdrawAmount <= address(this).balance, "Exceeds contract balance");
      (bool success,) = i_owner.call{value: withdrawAmount}("");
      require(success, "Error");
      emit FundsWithdrew(withdrawAmount, reason);
   }

   function isContract(address _address) public view returns (bool) {
      uint32 size;
      assembly {
        size := extcodesize(_address)
      }
      return (size > 0);
   }

   function getPriceOfETHInUSDwithDecimals() public view returns(uint256) {
      (, int256 answer, , , ) = s_priceFeed.latestRoundData();
      // ETH/USD rate in 18 digit
      return uint256(answer * 10000000000);
   }

   function getMemebershipFeeUSD() public pure returns(uint256){
      return MINIMUM_USD / 1e18;
   }

   function getOwner() public view returns(address){
      return i_owner;
   }

   function getNumberOfActiveMembers() external view returns(uint256){
      return membershipCount;
   }

   function getMemberStatus(address _member) public view returns(bool){
         Member memory member = membershipInfomation[_member];
         return member.membershipStatus;
     }
     
   function getMemberTokenId(address _member) public view returns(uint256){//need to update this function
      Member memory member = membershipInfomation[_member];
      return member.membershipId;
   }
  

   function getNFTContractAddress() external view returns(address){
      return address(membershipNFTContract);
   }

   function getPriceFeedAddress() external view returns(address){
      return address(s_priceFeed);
   }

   //testing function
   function getMemberInfo(address addr) external view returns(Member memory) {
      return membershipInfomation[addr];
   }
}
