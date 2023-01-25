pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import 'src/POWER.sol';
import 'src/TILES.sol';

contract TilesGeneralTest is Test {
    TILES tiles;
    POWER power;

    address alice = address(1); 
    address bob = address(2);

    using stdStorage for StdStorage;

    function setUp() public {
        vm.startPrank(alice);
        power = new POWER();
        tiles = new TILES(address(power));
        power.addController(address(tiles));
        vm.stopPrank();
        assertEq(power.balanceOf(alice), 50 ether);
    }

    function testMintSuccess() public {
        vm.startPrank(alice, alice);
        uint balance_prev = power.balanceOf(alice);
        uint tokenId1 = tiles.mint(1);
        assertEq(power.balanceOf(alice), balance_prev - tiles.MINT_PRICE_ERC20());
        assertEq(tokenId1, 1);
        // (uint8 x1, uint8 y1, , , , ) = tiles.getTileTrait(tokenId1);
        uint tokenId2 = tiles.mint(1);
        // (uint8 x2, uint8 y2, , , , ) = tiles.getTileTrait(tokenId2);
        uint tokenId3 = tiles.mint(1);
        // (uint8 x3, uint8 y3, , , , ) = tiles.getTileTrait(tokenId3);
        // console.log('x1=', x1, '; y1=', y1);
        // console.log('x2=', x2, '; y2=', y2);
        // console.log('x3=', x3, '; y3=', y3);
        vm.stopPrank();
        //three tokens: (13,8), (5,6), (7,10)
        // (uint8 x3, uint8 y3, uint8 exponent3, uint8 privileged3, uint256 token3, uint256 timestamp3) = tiles.getTileTrait(tokenId3);
    }

    function testNFTMoveSuccess() public {
        testMintSuccess();  //three tokens: (13,8), (5,6), (7,10)
        // first, moves token1 to boundary
        uint256 tokenId1 = 1;
        assertEq(tiles.getTokenIdFromXY(13,8), tokenId1);
        uint8[] memory moves = new uint8[](4);
        moves[0] = 1;
        moves[1] = 2;
        moves[2] = 0;
        moves[3] = 3;
        vm.prank(alice);
        tiles.move(moves, tokenId1);// move token1 right, up, left, down
        (uint8 x1, uint8 y1, , , , ) = tiles.getTileTrait(tokenId1);
        assertEq(x1, 0);
        assertEq(y1, 15);
        assertEq(tiles.getTokenIdFromXY(0, 15), tokenId1);
        assertEq(tiles.getTokenIdFromXY(13,8), 0);
        // second, moves token2 on top of token1
        uint256 tokenId2 = 2;
        assertEq(tiles.getTokenIdFromXY(5,6), tokenId2);
        uint8[] memory moves2 = new uint8[](2);
        moves2[0] = 0;
        moves2[1] = 3;
        vm.prank(alice);
        tiles.move(moves2, tokenId2);// move token1 right, up, left, down
        (uint8 x2, uint8 y2, , , , ) = tiles.getTileTrait(tokenId2);
        assertEq(x2, 0);
        assertEq(y2, 14);
        assertEq(tiles.getTokenIdFromXY(0, 14), tokenId2);
        assertEq(tiles.getTokenIdFromXY(5,6), 0);
    }

    function testNFTMergeSuccess() public {
        testNFTMoveSuccess(); // three tokens: (15,0), (14,0), (7,10)
        uint8 tokenId1 = 1;
        uint8 tokenId2 = 2;
        // first, merge token1 to token2, meaning token1 get burned, token2 increases exponent
        vm.prank(alice);
        tiles.merge(tokenId1,tokenId2,2);
        vm.expectRevert(bytes("ERC721: invalid token ID"));
        tiles.ownerOf(tokenId1);
        (, , uint8 exponent , , , ) = tiles.getTileTrait(tokenId2);
        assertEq(exponent, 2);
        // need to check not adjacent, not same owner, not same exponent cannot merge
    }

    function testNFTClaimSuccess() public {
        testNFTMergeSuccess();
        uint8 tokenId = 2;
        uint256 balance_prev = power.balanceOf(alice);
        vm.warp(3600*24);
        vm.prank(alice);
        tiles.claim(tokenId);
        assertEqDecimal((balance_prev + 2 * tiles.DAILY_RATE())/1e18, power.balanceOf(alice)/1e18, 6);
    }

    // function testPriviledgeSuccess() public {}

    function testAwardWinnerSuccess() public {
        // winner can become new 
        testMintSuccess();
        uint256 tokenId = 1;
        // stdstore.target(address(tiles)).sig("getTileTrait(uint256)")
        // .with_key(tokenId).depth(2).checked_write(11);
        // not working because exponent is shorter than 32 bytes!

        // handcode WINNING_EXPONENT to be 1
        vm.startPrank(alice);
        vm.expectRevert(bytes("POWER: only controller can mint"));
        power.mint(alice, 1 ether);
        tiles.setWinner(tokenId, alice);
        power.mint(alice, 1 ether);
        vm.stopPrank();
    }
}