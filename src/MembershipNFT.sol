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
import {Member} from "./MemberDeclaration.sol";

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
    //mapping(uint256 => string tokenUri) private s_tokenIdToUri; //dont'need this?

    

    //events
    event NFTMinted(address to, uint256 tokenId);
    event NFTFlipped(address owner, uint256 tokenId);
    event NFTBurned(address owner, uint256 tokenId);

    constructor(string memory currentMemberSvgUri, string memory formerMemberSvgUri) ERC721("MemberOwnershipNFT", "MNFT") Ownable(msg.sender) {
        daoContractAddress = msg.sender;
        s_tokenCounter = 0;
        s_currentMemberSvgUri = currentMemberSvgUri;
        s_formerMemberSvgUri = formerMemberSvgUri;
    }

    

    function mintNFT(address _to) public returns(uint256) {
        require(msg.sender == daoContractAddress, "You are not allowed to mint new NFTS!");
        _safeMint(_to, s_tokenCounter);
        tokenMembershipStatus[s_tokenCounter] = true;
        uint256 freshlyMintedTokenId = s_tokenCounter;
        s_tokenCounter = s_tokenCounter + 1;
        return freshlyMintedTokenId;
    }

    function updateNFT(uint256 _tokenId) public {
        require(msg.sender == daoContractAddress, "You are not allowed to mint flip NFTS!");
        tokenMembershipStatus[_tokenId] = false;
    }

    function burnNFT(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "You don't own this NFT");
        require(!getMembershipStatusBasedOnTokenId(_tokenId), "You are still and active member!");
        _burn(_tokenId);
    }

    //return a difference balance if they are no longer member of the DAO but still hold a NFT?


    function tokenURI(uint256 _tokenId) public view override returns(string memory){
        if(ownerOf(_tokenId) == address(0)){
            revert BasicNFT__TokenUriNotFound();
        }

        return getUri(_tokenId);
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


    function getUri(uint256 tokenId) public view returns(string memory){
        if (ownerOf(tokenId) == address(0)) {
            revert ERC721Metadata__URI_QueryFor_NonExistentToken();
        }
    
        bool activeStatus = tokenMembershipStatus[tokenId];

        string memory image = s_formerMemberSvgUri;
        string memory description = '", "description":"A former member of the DAO! This NFT Proves it! This NFT changes when a member leaves the DAO.", ';
        if (activeStatus) {
            image = s_currentMemberSvgUri;
            description = '", "description":"A current member of the DAO! This NFT Proves it! It will change if the member leaves the DAO.", ';
        }

    
        return string(
            abi.encodePacked(
                _baseURI(),
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            name(),
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

    function membershipStructUri() public view returns(string memory){  //used for testing and re-organizing json info, stll a work in progress. Need to figure out how to import a struct and given enough freedom to DAO
        //perhaps sometype of abi call?
        string memory description = '", "description":"A former member of the DAO! This NFT Proves it! This NFT changes when a member leaves the DAO.", ';
        address wallet;
        uint256 joinDate;
        uint256 membershipId;
        bool membershipStatus;

    
        return string(
            abi.encodePacked(
                _baseURI(),
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            name(),
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

    function getDAOAddress() external view returns(address) {
        return address(daoContractAddress);
    }

    function getCurrentMemberSVGUri() external view returns(string memory){
        return s_currentMemberSvgUri;
    }

    function getFormerMemberSVGUri() external view returns(string memory){
        return s_formerMemberSvgUri;
    }

}