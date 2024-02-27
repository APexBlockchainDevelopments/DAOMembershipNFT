// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Member} from "./MemberDeclaration.sol";

contract DAO {

   mapping (address => Member) private membershipInfomation; 
  
   function joinDAO() public payable{
      //add them to the dao
      Member memory newMember = Member({
         wallet: msg.sender,
         joinDate : block.timestamp,
         membershipId : block.number,
         membershipStatus : true
      });

      membershipInfomation[msg.sender] = newMember;
   }

   function getMemberStatus(address _member) public view returns(bool){
         Member memory member = membershipInfomation[_member];
         return member.membershipStatus;
     }
     
   function getMemberTokenId(address _member) public view returns(uint256){
      Member memory member = membershipInfomation[_member];
      return member.membershipId;
   }


   //testing function
   function getMemberInfo(address addr) external view returns(Member memory) {
      return membershipInfomation[addr];
   }
}

//perhaps member attribute 1, member attribute 2, member attribute 3??