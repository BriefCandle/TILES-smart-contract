// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "lib/openzeppelin-contracts/contracts/utils/Base64.sol";
import "./POWER.sol";

contract TILES is ERC721, Ownable {
    using Strings for uint256;

    // ERC20 Info
    POWER power;
    uint256 public constant DAILY_RATE = 1 ether;
    uint256 public constant BONUS_RATE = 0.5 ether;
    uint256 public constant MINT_PRICE_ERC20 = 1 ether;
    uint256 public constant MOVE_PRICE_ERC20 = 0.2 ether;
    uint256 public constant MERGE_PRICE_ERC20 = 0.3 ether;
    uint256 public PRIVILEGE_PRICE_LP = 1 ether; // change it to constant
    uint8 public constant PRIVILEGE_ACTIONS = 20; 
    address public LP;

    // Winning Info
    uint8 public WINNING_EXPONENT = 11; // 2048 // change it to constant 

    // NFT Info
    uint256 public constant MAX_SUPPLY = 2**14; // 16384
    uint256 public minted_amount;

    // SVG Info
    string[12] public TILE_COLOR = ['#000000', '#EEE4DA', '#EDE0C8', '#F2B179', '#F59563', '#F67C5F', '#F65E3B', '#EDCF72', '#EDCC61', '#EDC850','#EDC53F','#EDC22E'];

    bool public won = false;

    // Tile Info
    uint256 public constant MAX_EXIST = uint256(GRID_SIZE)**2 / 2;
    uint256 public exist_amount;
    struct TileTrait {
        uint8 x;
        uint8 y;
        uint8 exponent;
        uint8 privileged; // 0 is not privileged; 1 is
        uint256 tokenId;
        uint256 timestamp;
    }
    mapping(uint256 => TileTrait) public getTileTrait; // tokenId => TileTrait

    // Grid Info
    uint8 public constant GRID_SIZE = 16;
    mapping(uint8 => mapping(uint8 => uint256)) public getTokenIdFromXY; // x => y => tokenId

    event Minted(uint256 indexed tokenId, address owner, uint8 x, uint8 y);
    event Moved(uint256 indexed tokenId, uint8 x, uint8 y, address owner, uint8[] moves);
    event Merged(uint256 tokenId1, uint256 indexed tokenId2, address owner, uint8 x2, uint8 y2, uint8 action);
    event Claimed(uint256 indexed tokenId, address owner, uint256 award);
    event PrivilegeSet(uint256 tokenId);
    event WinnerSet(uint256 tokenId, address controller);


    constructor(address _erc20) ERC721("Tiles NFT", "TILES") {
        power = POWER(_erc20);
    }

    /*///////////////////////////////////////////////////////////////
                               MINT FUNCTION
    //////////////////////////////////////////////////////////////*/
    /// @notice Mint NFT function
    function mint(uint8 amount) public returns(uint256) {
        require(minted_amount + amount <= MAX_SUPPLY, "TILES: all tokens minted");
        require(exist_amount + amount <= MAX_EXIST, "TILES: max exist");
        require(amount > 0 && amount <= 5, 'TILES: invalid mint amount');
        for (uint i=0; i<amount; i++) {
            minted_amount++;
            exist_amount++;
            uint256 seed = pseudoRandom(minted_amount);
            (uint8 x, uint8 y) = selectXY(seed);
            getTileTrait[minted_amount] = TileTrait({
                x: x,
                y: y,
                exponent: 1,
                privileged: 0, 
                tokenId: minted_amount,
                timestamp: block.timestamp
            });
            getTokenIdFromXY[x][y] = minted_amount;
            _safeMint(msg.sender, minted_amount);

            emit Minted(minted_amount, msg.sender, x, y);
        }
        power.burn(msg.sender, MINT_PRICE_ERC20 * amount);
        return minted_amount;
    }

    /// @notice Select unoccupied x, y from grid
    function selectXY(uint256 seed) internal view returns(uint8 x, uint8 y) {
        x = uint8((seed & 0xFFFF) % GRID_SIZE);
        y = uint8((seed >> 16 & 0xFFFF) % GRID_SIZE);
        if (checkUnoccupiedXY(x,y)) return (x, y);
        selectXY(pseudoRandom(seed));
    }

    /// @notice Check if x, y is unoccupied from grid    
    function checkUnoccupiedXY(uint8 x, uint8 y) internal view returns(bool) {
        return getTokenIdFromXY[x][y] == 0 ? true : false;
    } 

    /// @notice Generate pseudo random uint256
    function pseudoRandom(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp,
            seed
        )));
    }

    /*///////////////////////////////////////////////////////////////
                               MOVE FUNCTION
    //////////////////////////////////////////////////////////////*/
    /// @notice Move Tile NFT on grid; action 0 for left, 1 right, 2 up, 3 down
    function move(uint8[] calldata moves, uint256 tokenId) public returns (uint8 x, uint8 y) {
        require(ownerOf(tokenId) == msg.sender, "TILES: not owner");
        x = getTileTrait[tokenId].x;
        y = getTileTrait[tokenId].y;
        getTokenIdFromXY[x][y] = 0;
        (x,y) = estimateDestination(moves, x, y);
        if (getTileTrait[tokenId].privileged < moves.length) {
            power.burn(msg.sender, MOVE_PRICE_ERC20 * (moves.length - getTileTrait[tokenId].privileged));
            if (getTileTrait[tokenId].privileged != 0) getTileTrait[tokenId].privileged = 0;
        } else getTileTrait[tokenId].privileged -= uint8(moves.length);
        getTileTrait[tokenId].x = x;
        getTileTrait[tokenId].y = y;
        getTokenIdFromXY[x][y] = tokenId;
        
        emit Moved(tokenId, x, y, msg.sender, moves);
    }

    function estimateDestination(uint8[] calldata moves, uint8 x, uint8 y) public view returns (uint8, uint8) {
        for (uint8 i = 0; i < moves.length; i++) {
            if (moves[i] == 0) x = moveLeft(x, y);
            if (moves[i] == 1) x = moveRight(x, y);
            if (moves[i] == 2) y = moveUp(x, y);
            if (moves[i] == 3) y = moveDown(x, y);
        }
        return (x,y);
    }

    function moveLeft(uint8 x, uint8 y) internal view returns (uint8) {
        require(x != 0, "TILES: leftest");
        for (uint8 i = x; i > 0; i--) {
            if (!checkUnoccupiedXY(i-1,y)) return i;
        }
        return 0;
    }

    function moveRight(uint8 x, uint8 y) internal view returns (uint8) {
        require(x != GRID_SIZE - 1, "TILES: rightest");
        for (uint8 i = x; i < GRID_SIZE - 1; i++) {
            if (!checkUnoccupiedXY(i+1,y)) return i;
        }
        return GRID_SIZE-1;
    }

    function moveUp(uint8 x, uint8 y) internal view returns (uint8) {
        require(y != 0, "TILES: highest");
        for (uint8 j = y; j > 0; j--) {
            if (!checkUnoccupiedXY(x,j-1)) return j;
        }
        return 0;
    }

    function moveDown(uint8 x, uint8 y) internal view returns (uint8) {
        require(y != GRID_SIZE - 1, "TILES: lowest");
        for (uint8 j = y; j < GRID_SIZE - 1; j++) {
            if (!checkUnoccupiedXY(x,j+1)) return j;
        }
        return GRID_SIZE-1;
    }

    /*///////////////////////////////////////////////////////////////
                               MERGE FUNCTION
    //////////////////////////////////////////////////////////////*/
    /// @notice Merge tokenId1 to tokenId2; merge 0 for left, 1 right, 2 up, 3 down
    function merge(uint256 tokenId1, uint256 tokenId2, uint8 action) public {
        require(ownerOf(tokenId1) == msg.sender, "TILES: 1 not owner");
        require(ownerOf(tokenId2) == msg.sender, "TILES: 2 not owner");
        require(action <= 3, "TILES: incorrect action");
        uint8 x1 = getTileTrait[tokenId1].x;
        uint8 y1 = getTileTrait[tokenId1].y;
        uint8 x2 = getTileTrait[tokenId2].x;
        uint8 y2 = getTileTrait[tokenId2].y;
        require(getTileTrait[tokenId1].exponent == getTileTrait[tokenId2].exponent, "TILES: exponent not equal");
        if (action == 0) require(x1-x2 == 1 && y1 == y2, "TILES: no adjct left");
        if (action == 1) require(x2-x1 == 1 && y1 == y2, "TILES: no adjct right");
        if (action == 2) require(y1-y2 == 1 && x1 == x2, "TILES: no adjct up");
        if (action == 3) require(y2-y1 == 1 && x1 == x2, "TILES: no adjct down");
        if (getTileTrait[tokenId1].privileged == 0 && getTileTrait[tokenId2].privileged == 0) {
            power.burn(msg.sender, MERGE_PRICE_ERC20);
            getTileTrait[tokenId2].privileged == 0; 
        } else {
            getTileTrait[tokenId2].privileged = (getTileTrait[tokenId1].privileged + getTileTrait[tokenId2].privileged - 1) / 2;
        }
        _burn(tokenId1);
        getTileTrait[tokenId2].timestamp = block.timestamp;
        getTileTrait[tokenId2].exponent++;
        getTokenIdFromXY[x1][y1] = 0;
        exist_amount--;

        emit Merged(tokenId1, tokenId2, msg.sender, x2, y2, action);
    }

    /*///////////////////////////////////////////////////////////////
                               CLAIM FUNCTION
    //////////////////////////////////////////////////////////////*/
    function claim(uint256 tokenId) public returns(uint256 award) {
        require(ownerOf(tokenId) == msg.sender, "TILES: not owner"); // implicitly requires token exist
        award = 2 ** (getTileTrait[tokenId].exponent - 1) * (block.timestamp - getTileTrait[tokenId].timestamp) * DAILY_RATE / 1 days;
        if (getTileTrait[tokenId].privileged != 0) {
            uint256 bonus_award = (getTileTrait[tokenId].exponent - 1) * (block.timestamp - getTileTrait[tokenId].timestamp) * BONUS_RATE / 1 days * 2 / 3; 
            award = award + bonus_award;
        }
        getTileTrait[tokenId].timestamp = block.timestamp;
        power.mint(msg.sender, award);

        emit Claimed(tokenId, msg.sender, award);
    }

    // function getClaimAmount()

    /*///////////////////////////////////////////////////////////////
                               TOKEN URI FUNCTION
    //////////////////////////////////////////////////////////////*/
    /// @notice Base64 encoded metadata
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name": "TILE #', tokenId.toString(), '", ',
                '"description": "A 2048-style tile-grid game. Owner of the first 2048 tile may control the project contract.", ',
                '"image": "data:image/svg+xml;base64,', Base64.encode(compileSVG(tokenId)),'", ',
                compileAttributes(tokenId),
            '}'
        );
        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(dataURI)
        ));
    }

    /// @notice Attributes in string
    function compileAttributes(uint256 tokenId) public view returns (string memory) {
        TileTrait memory trait = getTileTrait[tokenId];
        return string.concat(
            '"attributes":','[',
                '{"trait_type": "x", "value": "', uint256(trait.x).toString(), '"},', 
                '{"trait_type": "y", "value": "', uint256(trait.y).toString(), '"},',
                '{"trait_type": "exponent", "value": "', uint256(trait.exponent).toString(), '"},',
                '{"trait_type": "privileged", "value": "', uint256(trait.privileged).toString(), '"},',
                '{"trait_type": "timestamp", "value": "', trait.timestamp.toString(), '"}',
            ']'
        );
    }

    /// @notice SVG in bytes
    function compileSVG(uint256 tokenId) public view returns (bytes memory) {
        TileTrait memory trait = getTileTrait[tokenId];
        uint256 number = 2**uint256(trait.exponent);
        string memory svg = string.concat(
            '<svg width="100" height="100" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">',
            // tile color 
            '<rect width="100" height="100" rx="10" ry="10" style="fill: ', 
                trait.exponent < 12 ? TILE_COLOR[trait.exponent] : TILE_COLOR[0],
                '"></rect>',
            // privilege
            trait.privileged == 0 ? '' : '<path transform="translate(38, 8)" d="M12 .587l3.668 7.568 8.332 1.151-6.064 5.828 1.48 8.279-7.416-3.967-7.417 3.967 1.481-8.279-6.064-5.828 8.332-1.151z" fill="#776e65"></path>',
            // power
            '<text x="50" y="65" font-size="36" text-anchor="middle" fill="', trait.exponent <=2 ? "#776e65" : "white" ,'">', number.toString(), '</text>',
            // (x, y)
            '<text x="50" y="87" font-size="15" text-anchor="middle" fill="#776e65">(', uint256(trait.x).toString(), ', ', uint256(trait.y).toString(), ')</text>',
            '</svg>'
        );
        return abi.encodePacked(svg);
    }



    /*///////////////////////////////////////////////////////////////
                               PRIVILEGE FUNCTION
    //////////////////////////////////////////////////////////////*/
    /// @notice Award privilege to tokenId if sender has power; does not require ownerOf; require caller set approval for his lp first
    function setPrivilege(uint256 tokenId) public {
        require(getTileTrait[tokenId].privileged == 0, "TILES: already privileged");
        // power.burn(msg.sender, PRIVILEGE_PRICE_ERC20 * 2 ** (getTileTrait[tokenId].exponent - 1));
        require(LP != address(0), "TILES: LP not set");
        require(IERC20(LP).transfer(address(power), PRIVILEGE_PRICE_LP * 2 * getTileTrait[tokenId].exponent), "TILES: transfer fails");
        getTileTrait[tokenId].privileged += PRIVILEGE_ACTIONS;

        emit PrivilegeSet(tokenId);
    }

    function setLP(address _LP) external onlyOwner {
        LP = _LP;
    }

    /*///////////////////////////////////////////////////////////////
                               WINNER FUNCTION
    //////////////////////////////////////////////////////////////*/
    /// @notice Award winner certain rights when winning condition is met
    function setWinner(uint256 tokenId, address _controller) public {
        require(ownerOf(tokenId) == msg.sender, "TILES: not owner");
        require(getTileTrait[tokenId].exponent >= WINNING_EXPONENT, "TILES: not winner");
        require(won == false, "TILES: already won");
        won = true;
        power.changeController(_controller);

        emit WinnerSet(tokenId, _controller);
    }


    /*///////////////////////////////////////////////////////////////
                    TO BE DELETED SETTER FUNCTION
    //////////////////////////////////////////////////////////////*/
    function changeWinningExponent(uint8 _winningExponent) external onlyOwner {
        WINNING_EXPONENT = _winningExponent;
    }

    function changePrivilegePriceLP(uint256 _privilegePriceLP) external onlyOwner {
        PRIVILEGE_PRICE_LP = _privilegePriceLP;
    }
}