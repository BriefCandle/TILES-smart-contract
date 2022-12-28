pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import 'src/POWER.sol';
import 'src/TILES.sol';

contract TilesTest is Test {
    TILES tiles;
    POWER power;

    address alice = address(1); 
    address bob = address(2);

    function setUp() public {
        vm.startPrank(alice);
        power = new POWER();
        tiles = new TILES(address(power));
        power.addController(address(tiles));
        vm.stopPrank();
        assertEq(power.balanceOf(alice), 50 ether);
    }

    function testMintNFTSuccess() public {
        vm.startPrank(alice, alice);
        uint balance_prev = power.balanceOf(alice);
        uint tokenId1 = tiles.mintNFT();
        // assertEq(power.balanceOf(alice), balance_prev - tiles.MINT_PRICE_ERC20());
        assertEq(tokenId1, 1);
        // (uint8 x1, uint8 y1, uint8 exponent1, uint8 privileged1, uint256 token1, uint256 timestamp1) = tiles.getTileTrait(tokenId1);
        // console.log(x1, y1);
        // uint tokenId2 = tiles.mintNFT();
        // assertEq(tokenId2, 2);
        // (uint8 x2, uint8 y2, uint8 exponent2, uint8 privileged2, uint256 token2, uint256 timestamp2) = tiles.getTileTrait(tokenId2);
        // console.log(x2, y2);
        // uint tokenId3 = tiles.mintNFT();
        // assertEq(tokenId3, 3);
        // (uint8 x3, uint8 y3, uint8 exponent3, uint8 privileged3, uint256 token3, uint256 timestamp3) = tiles.getTileTrait(tokenId3);
        // console.log(x3, y3);
    }

    

    // function testNFTMoveSuccess() public {}

    // function testNFTMergeSuccess() public {}

    // function testNFTClaimSuccess() public {}

    // function testPriviledgeSuccess() public {}

    function testAwardWinnerSuccess() public {
        // winner can become new 
    }
}