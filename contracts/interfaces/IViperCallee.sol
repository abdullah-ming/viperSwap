// pragma solidity >=0.5.0;
pragma solidity ^0.5.16;

interface IViperCallee {
    function viperCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}