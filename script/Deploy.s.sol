pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "src/POWER.sol";
import 'src/TILES.sol';

contract DeployScript is Script {

    TILES tiles;
    POWER power;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // vm.broadcast(); 

        power = new POWER();
        tiles = new TILES(address(power));
        power.addController(address(tiles));

        vm.stopBroadcast();
    }
}