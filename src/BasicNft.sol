//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BasicNft is ERC721{
    error BasicNFT__TokenUriNotFound();
    mapping(uint256 => string tokenUri) private s_tokenIdToUri;

    uint256 private s_tokenCounter;

    constructor() ERC721("Dogie","DOG"){
        s_tokenCounter = 0;
    }

    function mintNFT(string memory tokenUri) public {
        s_tokenIdToUri[s_tokenCounter] = tokenUri;
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter = s_tokenCounter + 1;
    }

    function tokenURI(uint256 tokenId) public view override returns(string memory){
        if(ownerOf(tokenId) == address(0)){
            revert BasicNFT__TokenUriNotFound();
        }

        return s_tokenIdToUri[tokenId];
    }

    function getTokenCounter() public view returns(uint256){
        return s_tokenCounter;
    }
}