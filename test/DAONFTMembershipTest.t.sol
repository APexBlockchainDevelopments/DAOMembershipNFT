//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {DeployDAONFT} from "../script/DeployDAO.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DAO} from "../src/DAO.sol";
import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

contract DAONFTMembershipTest is StdCheats, Test{
    DAO public newDao;
    HelperConfig public helperConfig;

    function setUp() public {
        DeployDAONFT deployer = new DeployDAONFT();
        (newDao, helperConfig) = deployer.run();
    }

    function test_userCanJoinTheDAO() public{

    }

    //users can join dao
    //users get NFTs
    //uri
    //user can leave down
    //users can leave down
    //user that left have nft flipped
    //cant leaven without joining
    //users rejoining
    //users leave and get funds back
    //memberlist updates
    

}