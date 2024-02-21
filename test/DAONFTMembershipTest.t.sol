//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {DeployDAONFT} from "../script/DeployDAO.s.sol";
import {MembershipNFT} from "../src/MembershipNFT.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DAO} from "../src/DAO.sol";
import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract DAONFTMembershipTest is StdCheats, Test{
    DAO public newDao;
    HelperConfig public helperConfig;

    MembershipNFT public nftManagerContract;
    DeployDAONFT public deployer;

    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant GAS_PRICE = 1;

    address user = address(uint160(1)); 

    string activeSvg = vm.readFile("./images/active_member.svg");
    string formerSvg = vm.readFile("./images/former_member.svg");

    function setUp() public {
        deployer = new DeployDAONFT();
        (newDao, helperConfig) = deployer.run();
        nftManagerContract = MembershipNFT(newDao.getNFTContractAddress());
    }

    ///single user testing
    function test_revertIfUserDoesNotSendEnoughFunds() public {
        address firstUser = address(uint160(1));
        vm.deal(firstUser, STARTING_USER_BALANCE);
        vm.startPrank(firstUser);
        vm.expectRevert("You need to spend more ETH!");
        newDao.joinDAO{value: 0.1 ether}();
        assertEq(newDao.getNumberOfActiveMembers(), 0);
        assertEq(newDao.getMemberStatus(firstUser), false);
        vm.stopPrank();
    }

    function test_userCanJoinTheDAO() public {
        address firstUser = address(uint160(1));
        vm.deal(firstUser, STARTING_USER_BALANCE);
        vm.startPrank(firstUser);
        uint256 daoEntryFee = newDao.getMemebershipFeeUSD();
        uint256 entryFeeInWei = (daoEntryFee * 10**36) / newDao.getPriceOfETHInUSDwithDecimals();  //this math sucks, needs a fix
        newDao.joinDAO{value: entryFeeInWei}(); 
        assertEq(newDao.getNumberOfActiveMembers(), 1);
        assertEq(newDao.getMemberStatus(firstUser), true);
        vm.stopPrank();

        // final check json URI of fresh member!
        uint256 memberId = newDao.getMemberTokenId(user);
        assertEq(nftManagerContract.tokenURI(memberId), getCurrentMemberUri(true));

    }

    modifier singleUserJoinsDao() {
        vm.deal(user, STARTING_USER_BALANCE);
        vm.startPrank(user);
        uint256 daoEntryFee = newDao.getMemebershipFeeUSD();
        uint256 entryFeeInWei = (daoEntryFee * 10**36) / newDao.getPriceOfETHInUSDwithDecimals();  //this math sucks, needs a fix
        newDao.joinDAO{value: entryFeeInWei}();  //fix this math to get a precise amount
        vm.stopPrank();
        _;
    }

    function test_userCantHoldTwoMemberships() public singleUserJoinsDao{
        vm.startPrank(user);
        uint256 daoEntryFee = newDao.getMemebershipFeeUSD();
        uint256 entryFeeInWei = (daoEntryFee * 10**36) / newDao.getPriceOfETHInUSDwithDecimals();  //this math sucks, needs a fix
        vm.expectRevert("You are already a member!");
        newDao.joinDAO{value: entryFeeInWei}(); 
    }

    function test_userCanLeaveDao() public singleUserJoinsDao(){ 
        uint256 membershipCountBeforeUserLeaves = newDao.getNumberOfActiveMembers();
        uint256 daoContractBalance = address(newDao).balance;
        uint256 expectedRefund = daoContractBalance / membershipCountBeforeUserLeaves;
        uint256 currentuserBalance = address(user).balance;
        vm.startPrank(user);
        newDao.leaveDAO();
        vm.stopPrank();


        assertEq(newDao.getNumberOfActiveMembers(), membershipCountBeforeUserLeaves - 1); // users are one less
        assertEq(address(newDao).balance, daoContractBalance - expectedRefund);//contract has expected less balance
        assertEq(address(user).balance, currentuserBalance + expectedRefund);//user got the funds
        
        uint256 memberId = newDao.getMemberTokenId(user);
        assertEq(nftManagerContract.getMembershipStatusBasedOnTokenId(memberId), false); //based on NFTmanagerContract
        assertEq(newDao.getMemberStatus(user), false); //based on Dao Contract
        assertEq(nftManagerContract.tokenURI(memberId), getCurrentMemberUri(false));
    }

    //fuzz test users can join dao
    function test_AmountOfUsersCanJoinDao() public {
        uint256 daoEntryFee = newDao.getMemebershipFeeUSD();
        uint256 entryFeeInWei = (daoEntryFee * 10**36) / newDao.getPriceOfETHInUSDwithDecimals(); 

        for(uint160 i = 0; i < 50; i++){  //once it hits 90 memory limit?
            address loopingUser = address((i+100));  //+100 so that we dont use the 0x0 address
            vm.deal(loopingUser, STARTING_USER_BALANCE);
            vm.startPrank(loopingUser);
            newDao.joinDAO{value: entryFeeInWei}(); 
            uint256 memberId = newDao.getMemberTokenId(loopingUser);
            vm.stopPrank();

            assertEq(newDao.getNumberOfActiveMembers(), i + 1); // users are one less
            assertEq(address(newDao).balance, (newDao.getNumberOfActiveMembers() * entryFeeInWei));//contract has expected balance
            assertEq(address(loopingUser).balance, STARTING_USER_BALANCE - entryFeeInWei);  //user sent the funds
            assertEq(nftManagerContract.getMembershipStatusBasedOnTokenId(memberId), true); //based on NFTmanagerContract
            assertEq(newDao.getMemberStatus(loopingUser), true); //based on Dao Contract
            assertEq(nftManagerContract.tokenURI(memberId), getCurrentMemberUri(true)); //Token URI
        }
    }

    modifier multipleUsersJoin () {
        uint256 daoEntryFee = newDao.getMemebershipFeeUSD();
        uint256 entryFeeInWei = (daoEntryFee * 10**36) / newDao.getPriceOfETHInUSDwithDecimals(); 

        for(uint160 i = 0; i < 50; i++){  //once it hits 90 memory limit?
            address loopingUser = address((i+100));  //+100 so that we dontuse the 0x0 address
            vm.deal(loopingUser, STARTING_USER_BALANCE);
            vm.startPrank(loopingUser);
            newDao.joinDAO{value: entryFeeInWei}(); 
            vm.stopPrank();
        }
        _;
    }


    function test_singleUserLeavesAfterMultipleJoin() public multipleUsersJoin {
        address leavingUser = address(110);

        uint256 membershipCountBeforeUserLeaves = newDao.getNumberOfActiveMembers();
        uint256 daoContractBalance = address(newDao).balance;
        uint256 expectedRefund = daoContractBalance / membershipCountBeforeUserLeaves;
        uint256 currentuserBalance = address(leavingUser).balance;
        vm.startPrank(leavingUser);
        newDao.leaveDAO();
        vm.stopPrank();

        //user that left
        assertEq(newDao.getNumberOfActiveMembers(), membershipCountBeforeUserLeaves - 1); // users are one less
        assertEq(address(newDao).balance, daoContractBalance - expectedRefund);//contract has expected less balance
        assertEq(address(leavingUser).balance, currentuserBalance + expectedRefund);//user got the funds
        uint256 memberId = newDao.getMemberTokenId(leavingUser);
        assertEq(nftManagerContract.getMembershipStatusBasedOnTokenId(memberId), false); //based on NFTmanagerContract
        assertEq(newDao.getMemberStatus(leavingUser), false); //based on Dao Contract
        assertEq(nftManagerContract.tokenURI(memberId), getCurrentMemberUri(false));

    }

    function test_multipleUsersLeave() public multipleUsersJoin {
        uint256 startingMembershipcount = newDao.getNumberOfActiveMembers();
        uint256 startingContractBalance = address(newDao).balance;

        for(uint160 i = 0; i < 10; i++){  
            address loopingUser = address((i+100)); 
            vm.deal(loopingUser, STARTING_USER_BALANCE);
            vm.startPrank(loopingUser);
            newDao.leaveDAO();
            vm.stopPrank();
        }

        assertEq(startingMembershipcount - 10, newDao.getNumberOfActiveMembers());
        assert(startingContractBalance > address(newDao).balance);
        
    }

    function test_fuzzTestRandomTokens(uint256 _memberId) public multipleUsersJoin {
        vm.assume(_memberId < 50);
        
        uint256 startingMembershipcount = newDao.getNumberOfActiveMembers();
        uint256 startingContractBalance = address(newDao).balance;

        for(uint160 i = 0; i < 10; i++){  
            address loopingUser = address((i+100)); 
            vm.deal(loopingUser, STARTING_USER_BALANCE);
            vm.startPrank(loopingUser);
            newDao.leaveDAO();
            vm.stopPrank();
        }

        bool memberStatus = nftManagerContract.getMembershipStatusBasedOnTokenId(_memberId); //based on NFT Contract
        assertEq(nftManagerContract.tokenURI(_memberId), getCurrentMemberUri(memberStatus)); //Token URI
    }


    //users rejoining
    function test_userCanRejoin() public singleUserJoinsDao {
        vm.startPrank(user);
        newDao.leaveDAO();
        newDao.joinDAO{value : 1e18}();
        assertEq(newDao.getNumberOfActiveMembers(), 1);
        assertEq(newDao.getMemberStatus(user), true);
        vm.stopPrank();
        uint256 memberId = newDao.getMemberTokenId(user);
        assertEq(nftManagerContract.tokenURI(memberId), getCurrentMemberUri(true));
    }

    //cant burn
    function test_cantBurnIfNotOwner() public singleUserJoinsDao{
        address randomUser = makeAddr("random");
        vm.prank(randomUser);
        vm.expectRevert("You dont own this NFT");
        nftManagerContract.burnNFT(0);
    }

    function test_cantBurnifStillMember() public singleUserJoinsDao{
        vm.startPrank(user);
        uint256 tokenId = newDao.getMemberTokenId(user);
        vm.expectRevert("You are still and active member!");
        nftManagerContract.burnNFT(tokenId);
        vm.stopPrank();

    }
    //burn
    function test_nftCanBurnAfterLeaving() public singleUserJoinsDao {
        vm.startPrank(user);
        newDao.leaveDAO();
        uint256 tokenId = newDao.getMemberTokenId(user);
        nftManagerContract.burnNFT(tokenId);
        vm.stopPrank();
        assertEq(nftManagerContract.balanceOf(user), 0);
    }

    function test_contractCantJoinTheDao() public {
        SampleContract sampleContract = new SampleContract();
        vm.deal(address(sampleContract), 10e18);
        vm.prank(address(sampleContract));
        vm.expectRevert("Contracts are not allowed to join the dao");
        newDao.joinDAO{value: 1e18}();
    }

    function test_nonOwnerCantWithDrawFunds() public multipleUsersJoin {
        address randomUser = makeAddr("random");
        vm.prank(randomUser);
        vm.expectRevert("You are not allowed to withdraw funds!");
        newDao.ownerWithdrawFunds(1000000000000000000, "I want money");
    }


    function test_ownerCanWithdrawFunds() public multipleUsersJoin {
        uint256 withdrawAmount = 1e18;
        address ownerOfDao = newDao.getOwner();

        uint256 contractBalanceBeforeWithdraw = address(newDao).balance;
        uint256 balanceOfOwnerBeforeWithdraw = ownerOfDao.balance;
        vm.prank(ownerOfDao);
        newDao.ownerWithdrawFunds(withdrawAmount, "Withdrawing to fund outsourced project");

        assertEq(contractBalanceBeforeWithdraw - withdrawAmount, address(newDao).balance);
        assertEq(ownerOfDao.balance , withdrawAmount + balanceOfOwnerBeforeWithdraw);
    }

    function test_userGetsLessAfterOwnerTakesSomeFundsOut() public multipleUsersJoin {
        uint256 withdrawAmount = 1e18;
        address ownerOfDao = newDao.getOwner();

        uint256 contractBalanceBeforeWithdraw = address(newDao).balance;
        uint256 balanceOfOwnerBeforeWithdraw = ownerOfDao.balance;
        vm.prank(ownerOfDao);
        newDao.ownerWithdrawFunds(withdrawAmount, "Withdrawing to fund outsourced project");

        address leavingUser = address((110));
        uint256 leavingUserBalanceBeforeLeavingDao = leavingUser.balance;
        vm.prank(leavingUser);
        newDao.leaveDAO();

        uint256 daoEntryFee = newDao.getMemebershipFeeUSD();
        uint256 entryFeeInWei = (daoEntryFee * 10**36) / newDao.getPriceOfETHInUSDwithDecimals(); 

        assert(leavingUserBalanceBeforeLeavingDao != leavingUser.balance + entryFeeInWei);
        assertEq(leavingUser.balance, leavingUserBalanceBeforeLeavingDao + (address(newDao).balance / newDao.getNumberOfActiveMembers() ));
    }


    //test cant transfer
    function test_nftCantTransfer() public singleUserJoinsDao {
        vm.startPrank(user);
        uint256 memberId = newDao.getMemberTokenId(user);
        address receiver = makeAddr("receiver");
        vm.expectRevert();
        nftManagerContract.safeTransferFrom(user, receiver, memberId);
        vm.stopPrank();
    }


    //basic generic testing
    function test_genericTesting() public {
        assertEq(newDao.getMemebershipFeeUSD(), 1000);
        assertEq(newDao.getOwner(), address(this));
        assertEq(newDao.getNFTContractAddress(), address(nftManagerContract));
        if (block.chainid == 11155111) {
            assertEq(newDao.getPriceFeedAddress(), 0x694AA1769357215DE4FAC081bf1f309aDC325306);
        } 
    }

    //helper functions to compare resulting strings
    function svgToImageURI(string memory svg) public pure returns(string memory){
        string memory baseURI = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(svg)))
        );
        return string(abi.encodePacked(baseURI, svgBase64Encoded));
    } 

    function getCurrentMemberUri(bool activeStatus) public view returns(string memory){

        string memory image = svgToImageURI(formerSvg);
        string memory description = '", "description":"A former member of the DAO! This NFT Proves it! This NFT changes when a member leaves the DAO.", ';
        if (activeStatus) {
            image = svgToImageURI(activeSvg);
            description = '", "description":"A current member of the DAO! This NFT Proves it! It will change if the member leaves the DAO.", ';
        }

    
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            'MemberOwnershipNFT',
                            description,
                            '"attributes": [{"trait_type": "Memberstatus", "active": ',
                            activeStatus,
                            '}], "image":"',
                            image,
                            '"}'
                        )
                    )
                )
            )
        );
    }


}

contract SampleContract {
    receive() external payable{}
}