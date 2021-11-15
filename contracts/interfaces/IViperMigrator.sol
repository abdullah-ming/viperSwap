pragma solidity >=0.5.16;

interface IViperMigrator {
    function migrate(address token, uint amountTokenMin, uint amountATPMin, address to, uint deadline) external;
}