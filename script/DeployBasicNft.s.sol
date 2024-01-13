//SPDX-License-Identifier: MIT

import {Script} from "forge-std/Script.sol";
import {BasicNft} from "../src/BasicNft.sol";
import {console} from "forge-std/console.sol"; 

pragma solidity ^0.8.20;

contract DeployBasicNft is Script{
    uint256 constant public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 public deployerKey;

    function run() external returns(BasicNft){
        if(block.chainid == 31337){
            deployerKey = DEFAULT_ANVIL_PRIVATE_KEY;
        } else {
            deployerKey = vm.envUint("SEPOLIA_PRIVATE_KEY2");
        }

        vm.startBroadcast(deployerKey);
        BasicNft basicNft = new BasicNft();
        vm.stopBroadcast();
        return basicNft;
    }
}