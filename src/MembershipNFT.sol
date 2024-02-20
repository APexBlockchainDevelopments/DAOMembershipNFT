// SPDX-License-Identifier: MIT

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

pragma solidity 0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract MembershipNFT is ERC721, Ownable {
    // errors
    error MembershipNFT__SoulboundTokenCannotBeTransfered();
    error BasicNFT__TokenUriNotFound();
    error ERC721Metadata__URI_QueryFor_NonExistentToken();

    //state variables
    string private s_currentMemberSvgUri;
    string private s_formerMemberSvgUri;
    uint256 private s_tokenCounter;
    address private daoContractAddress;
    mapping(uint256 => bool) private tokenMembershipStatus;
    mapping(uint256 => string tokenUri) private s_tokenIdToUri;

    

    //events??
    //new nft minted
    //nft flipped
    //nft burned

    constructor(string memory currentMemberSvgUri, string memory formerMemberSvgUri) ERC721("MemberOwnershipNFT", "MNFT") Ownable(msg.sender) {
        daoContractAddress = msg.sender;
        s_tokenCounter = 0;
        s_currentMemberSvgUri = currentMemberSvgUri;
        s_formerMemberSvgUri = formerMemberSvgUri;
    }

    

    function mintNFT(address _to) public returns(uint256) {
        require(msg.sender == daoContractAddress, "You are not allowed to mint new NFTS!");
        s_tokenIdToUri[s_tokenCounter] = getCurrentMemberUri(s_tokenCounter);
        _safeMint(_to, s_tokenCounter);
        tokenMembershipStatus[s_tokenCounter] = true;
        uint256 freshlyMintedTokenId = s_tokenCounter;
        s_tokenCounter = s_tokenCounter + 1;
        return freshlyMintedTokenId;
    }

    function flipNFT(uint256 _tokenId) public {
        require(msg.sender == daoContractAddress, "You are not allowed to mint flip NFTS!");
        tokenMembershipStatus[_tokenId] = false;
    }

    function burnNFT(uint256 _tokenId) public onlyOwner {
        require(getMembershipStatusBasedOnTokenId(_tokenId), "You are still and active member!");
        _burn(_tokenId);
    }

    //return a difference balance if they are no longer member of the DAO but still hold a NFT?


    function tokenURI(uint256 _tokenId) public view override returns(string memory){
        if(ownerOf(_tokenId) == address(0)){
            revert BasicNFT__TokenUriNotFound();
        }

        return getCurrentMemberUri(_tokenId);
    }


    /// @notice Override of transferFrom to prevent any transfer.
    function transferFrom(address, address, uint256) public pure override {
        // Soulbound token cannot be transfered
        revert MembershipNFT__SoulboundTokenCannotBeTransfered();
    }

    function getMembershipStatusBasedOnTokenId(uint256 _tokenId) public view returns(bool){
        return tokenMembershipStatus[_tokenId];
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }


    function getCurrentMemberUri(uint256 tokenId) public view returns(string memory){
        if (ownerOf(tokenId) == address(0)) {
            revert ERC721Metadata__URI_QueryFor_NonExistentToken();
        }
    
        bool activeStatus = tokenMembershipStatus[tokenId];
        //if this doesn't work well do an if statement
        string memory image;
        if(activeStatus){
            image = s_currentMemberSvgUri;
        } else {
            image = s_formerMemberSvgUri;
        }
    
        return string(
            abi.encodePacked(
                _baseURI(),
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            name(),
                            '", "description":"A current member of the DAO! This NFT Proves it! It will change if the member leaves the DAO.", ',
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