## 1. Overview
TILES is a 2048-style crypto game. On a 16x16 grid, players can mint, move, and merge TILES with one another. The first player with a tile reaching the number 2048 (exponent #11) can take control of this project.

This is an on-chain mini game developed primarily to demonstrate a decentralized NFT market protocol which
1) uses bid-and-ask mechanism
2) allows any ERC20 as payment method
3) adopts a uniswap-like market factory that maps an nft contract to a unique market contract
4) allows configuration of bidding strategies (for example, bidding on specific traits) (upcoming)

- https://github.com/BriefCandle/nft-market

The game consists of two smart contracts: 
1) TILES.sol --> NFT
2) POWER.sol --> ERC20

## 2. Gameplay
### General Rule
A player can use $POWER (swapped from UniswapV2-LP pool) to mint a Tile which can
1) automatically generate $POWER, 
2) move left, right, up, & down on the grid,
3) merge with adjacent Tile from the same owner && of the same exponent #.

### LP & Privilege
Providing Liquidity (specifically, gifting UniswapV2-LP to the $POWER contract) would grant an TILE a "privileged" status. 

A privileged TILE has 2 main benefits: 
1) need not burn $POWER to perfrom Gameplay actions 2 - 3 listed above.
2) obtain additional bonus award in gameplay action 1) listed above:

```bonus_award = (getTileTrait[tokenId].exponent - 1) * (block.timestamp - getTileTrait[tokenId].timestamp) * BONUS_RATE / 1 days * 2 / 3; ```

Liquidity is locked until the game winner is decided.

### Minting
- Total Supply: 2**14 TILEs;
- Each TILE requires $POWER to mint
- When half of the gird is occupied by TILEs, minting stops until old TILEs are merged to reduce the amount of TILEs on grid. 

### Game Winner 
Whoever obtains the first 2048 Tile may setWinner()to gain TOTAL control of the $POWER contract. New controller may transfer any ERC20 the $POWER contract owns (i.e., LP), mint new $POWER to anyone, or burn old $POWER from anyone. 

## 3. Comments 
### No Owner Privilege
Once the NFT & ERC20 contracts are deployed, there is nothing the deployer can do. No extra minting, mining, claiming, pausing, trasnferring, authorizing, or etc. Future work could be done to allow $POWER the governance rights to change game rules.

### Trading with $POWER
Merge would be difficult when the grid is populated with TILEs players do not own. In such case, trading TILEs with each other is recommended. 

With TILE NFTs being the $POWER-generating asset, it makes economic sense to trade them with $POWER as the main payment method. An ERC20-based NFT market protocol would be used:
- https://github.com/BriefCandle/nft-market

### Contract-Based Alliance 
Getting a 2048 TILE could be extremely difficult. It is expected that a group of players can form an alliance based on smart contract to win the game and set new controller to be a smart contract.

## 4. Smart Contract
### TILES.sol
Total 250 lines covering the game constants, grid mapping, tokenURI, mint(), move(), merge(), claim(), setPrivilege(), setWinner(). Very straightforward. 

### POWER.sol
Total 40 lines. Very straightforward. 

## 5. Testing
```$Forge test ```

## 6. Testnet
(coming soon)

Complete the google form to participate: https://forms.gle/JNdnuZHU93dmMZQT8

## 7. Front-end
(coming soon)

Please let me know if you want to contribute: Discord: Brief_Kandle#6146
