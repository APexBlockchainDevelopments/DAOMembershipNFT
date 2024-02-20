// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {DAO} from "../src/DAO.sol";

contract DeployDAONFT is Script {


    function run() external returns (DAO, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        address priceFeed = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        DAO newDAO = new DAO(msg.sender, priceFeed);
        vm.stopBroadcast();
        return (newDAO, helperConfig);
    }
}