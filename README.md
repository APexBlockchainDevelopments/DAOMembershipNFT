## DAO Membership NFTs

## Concept
This project is a working relationship between a NFT contract and a simple DAO. Although DAOs and NFTs can come in many flavors this project was designed to have membership of the DAO represented by a NFT. When a user leaves the DAO the NFT is then changed to different NFT data to represent their membership status. 


## Inspiration
The world of NFTs and their utility is vast. Although some offer no ultility, others act like a members pass or a represenation of being part of a club. This could be used to access exclusive content, voting rights, physical access to concepts or events....etc. However this comes with some draw backs. Often times it's left up to front end interfaces or customized code to allow owners of those NFTs to access the ultility associated with them. 


## Intentions
This project is designed so when a user pays an entry fee to become a member of a DAO a NFT is then minted to their wallet. This is a "badge" that users can show off that they are part of the DAO. Whether it's bragging rights, or privlegded access this NFT is their "ticket" and "proof" they are part of the DAO. This NFT is soulbound. If a user leaves the DAO the smart contracts are designed in a manner to then flip the NFT to be different content. The user also has the option to "burn" their NFT once they leave the organization. 

## Advantages
Although NFTs are already used to get access to various things, this contract is a way to increase accountability and security within the organization. Since the NFT is soulbound a user cannot resell their NFT on the open market at a different price. This makes sure the playing field is level for all those who wish to become a member of the DAO. This also prevents unwanted or former members from accessing the DAO. Hypothetically if a user only has a standard ERC-721 to represent organization membership, if they renounce their membership in any such form, the NFT still resides in their wallet. In this project the NFT still resides in their wallet however since the content is then switched so that it is easily noticed that the individual is no longer a member. There are also various "getter" functions and data structures so that it is easy to query if a member is active or not. 

Example 1: A member is acting malicously to the DAO and is removed by an admin or by a group vote the NFT flips to new data and the data strucutres are updated. 
<br/>
<br/>
Example 2: A organization is using NFTs as tickets for a real world meet-up. A malicous user comes along and decides to buy up as many tickets as possible in order to resell them on the seconardy market. Since the NFT is soulbound this individual would not be able to resell them and is not able to affect the price. The price is a static price set by the DAO. 
<br/>
<br/>
Example 3: A individual joins a DAO with the best intentions. This is a mutual fund lending DAO. The group uses a telegram channel that checks for NFT ownership and status for access to the telegram channel. Members vote on where to send group funds to fund other projects. However this individual decides it's time to move on, he decides to exit the group receiving a some funds in return for his share of the group. This individual does not need to find a buyer for the NFT and it automaticall is updated so that he is no longer available to receive DAO member benefits. 
<br/>
<br/>
Example 4: A organziation is using NFTs with QR codes to attend a real world event. The NFT acts as a ticket to attend the event. The organziation wishes to allow event attenders to vote on what things would happen at that event. This project would allow NFT holders to vote and submit proposals for their DAO. Since the DAO is the main contract, it could track member status, manage funds...etc. while still allowing all of the NFT functionality. 

## Goals:
This eventual goal is to build it into it's own standard contract that is an extension of the ERC-721. From there it would be ideal to submit this standard to the community as an EIP and perhaps even become a new standard in the Ethereum ecosystem. It's not meant to replace the standard ERC or to be a replacement for the NFT standard, rather an extension that DAOs could easily implement to help manager their organziation and reward their users. 

## TODO:
There's much to do with this project. Mainly most of the functionality needs to be moved to the NFTExtension Contract. With the goals and intentions in mind, it should be easy for a DAO to implent the NFTExention contract easily. Functions should be available to the DAO contract to allow it to change NFTs, mint NFTs...etc. Another conept that would be possible to implement is DAO member stats into the NFT. For example a DAO admin, or majority holder, or if have been a member for many years or voted on many successfuly projects. 
