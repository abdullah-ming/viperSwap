pragma solidity =0.5.16;

import '../ViperERC20.sol';

contract ERC20 is ViperERC20 {
    constructor(uint _totalSupply) public {
        _mint(msg.sender, _totalSupply);
    }
}