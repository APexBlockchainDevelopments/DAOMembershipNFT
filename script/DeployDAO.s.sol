// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {DAO} from "../src/DAO.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract DeployDAONFT is Script {


    function run() external returns (DAO, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        address priceFeed = helperConfig.activeNetworkConfig();   
        string memory activeSvg = vm.readFile("./images/active_member.svg");
        string memory formerSvg = vm.readFile("./images/former_member.svg");

        vm.startBroadcast();
        DAO newDAO = new DAO(msg.sender, priceFeed, svgToImageURI(activeSvg), svgToImageURI(formerSvg));
        vm.stopBroadcast();
        return (newDAO, helperConfig);
    }

    function svgToImageURI(string memory svg) public pure returns(string memory){
       string memory baseURI = "data:image/svg+xml;base64,";
       string memory svgBase64Encoded = Base64.encode(
           bytes(string(abi.encodePacked(svg)))
       );
       return string(abi.encodePacked(baseURI, svgBase64Encoded));
   } 
}