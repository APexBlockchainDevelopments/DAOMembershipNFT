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

    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant GAS_PRICE = 1;

    address user = address(uint160(1)); 

    string activeSvg = vm.readFile("./images/active_member.svg");
    string formerSvg = vm.readFile("./images/former_member.svg");

    function setUp() public {
        DeployDAONFT deployer = new DeployDAONFT();
        (newDao, helperConfig) = deployer.run();
        nftManagerContract = MembershipNFT(newDao.getNFTContractAddress());
    }

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
        string memory jsonTokenURI = nftManagerContract.tokenURI(0);
        string memory expectedJsonTokenURI = svgToImageURI(activeSvg);

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

    function test_userCantJoinDAOTwice() public singleUserJoinsDao{
        vm.startPrank(user);
        uint256 daoEntryFee = newDao.getMemebershipFeeUSD();
        uint256 entryFeeInWei = (daoEntryFee * 10**36) / newDao.getPriceOfETHInUSDwithDecimals();  //this math sucks, needs a fix
        vm.expectRevert("You are already a member!");
        newDao.joinDAO{value: entryFeeInWei}();  //fix this math to get a precise amount
    }

    function test_userCanLeaveDao() public singleUserJoinsDao(){  //clean up this function big time, lol
        vm.startPrank(user);
        newDao.leaveDAO();
        vm.stopPrank();
        bool result= nftManagerContract.getMembershipStatusBasedOnTokenId(0);
        console.log(result);
        string memory jsonTokenURI = nftManagerContract.tokenURI(0);
    }

    //fuzz test users can join dao
    //users get NFTs
    //uri
    //user can leave dao
    //users can leave dao
    //user that left have nft flipped
    //cant leaven without joining
    //users rejoining
    //users leave and get funds back
    //memberlist updates


    //helper function to compare resulting strings
    function svgToImageURI(string memory svg) public pure returns(string memory){
        string memory baseURI = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(svg)))
        );
        return string(abi.encodePacked(baseURI, svgBase64Encoded));
    } 


}