pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";


contract POWER is ERC20 {
    // uint256 constant MAX_SUPPLY = 1000000 ether;

    address public controller;

    event ControllerAdded(address controller);
    event ControllerChanged(address controller);

    constructor() ERC20("Power", "POWER") {
        _mint(msg.sender, 50 ether); // mint the initial amount to setup liquidity
    }

    /// @notice mints erc20 to a recipient
    function mint(address to, uint256 amount) external {
        require(msg.sender == controller, "POWER: only controller can mint");
        // require(totalSupply() <= MAX_SUPPLY, "POWER: Max supply reached");
        _mint(to, amount);
    }

    /// @notice burns erc20 from a holder
    function burn(address from, uint256 amount) external {
        require(msg.sender == controller, "POWER: only controller can burn");
        _burn(from, amount);
    }

    /// @notice setup controller the first time
    function addController(address _tiles) external {
        require(controller == address(0), "POWER: controller is set");
        controller = _tiles;

        emit ControllerAdded(_tiles);
    }

    /// @notice change a new controller who has the ability to burn and mint
    function changeController(address _controller) external {
        require(msg.sender == controller, "POWER: only controller can change");
        controller = _controller;

        emit ControllerChanged(_controller);
    }

    /// @notice only new controller, i.e., winner, may transfer an erc20 this contract owns
    function transferERC20(address _erc20, uint _amount, address recipient) external {
        require(msg.sender == controller, "POWER: only controller can transfer");
        require(IERC20(_erc20).transfer(recipient, _amount), "POWER: transfer fails");
    }
}