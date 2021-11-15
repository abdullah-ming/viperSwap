// pragma solidity ^0.6.6;
pragma solidity ^0.5.16;

import './libraries/TransferHelper.sol';
import './interfaces/IViperMigrator.sol';
import './interfaces/IUniswapV1Factory.sol';
import './interfaces/IUniswapV1Exchange.sol';
import './interfaces/IViperRouter01.sol';
import './interfaces/IERC20.sol';

contract ViperMigrator is IViperMigrator {
    IUniswapV1Factory factoryV1;
    IViperRouter01 router;

    constructor(address _factoryV1, address _router) public {
        factoryV1 = IUniswapV1Factory(_factoryV1);
        router = IViperRouter01(_router);
    }

    // needs to accept ATP from any v1 exchange and the router. ideally this could be enforced, as in the router,
    // but it's not possible because it requires a call to the v1 factory, which takes too much gas
    function() external payable {}

    function migrate(address token, uint amountTokenMin, uint amountATPMin, address to, uint deadline)
        external
    {
        IUniswapV1Exchange exchangeV1 = IUniswapV1Exchange(factoryV1.getExchange(token));
        uint liquidityV1 = exchangeV1.balanceOf(msg.sender);
        require(exchangeV1.transferFrom(msg.sender, address(this), liquidityV1), 'TRANSFER_FROM_FAILED');
        (uint amountATPV1, uint amountTokenV1) = exchangeV1.removeLiquidity(liquidityV1, 1, 1, uint(-1));
        TransferHelper.safeApprove(token, address(router), amountTokenV1);
        (uint amountTokenV2, uint amountATPV2,) = router.addLiquidityATP.value(amountATPV1)(
            token,
            amountTokenV1,
            amountTokenMin,
            amountATPMin,
            to,
            deadline
        );
        if (amountTokenV1 > amountTokenV2) {
            TransferHelper.safeApprove(token, address(router), 0); // be a good blockchain citizen, reset allowance to 0
            TransferHelper.safeTransfer(token, msg.sender, amountTokenV1 - amountTokenV2);
        } else if (amountATPV1 > amountATPV2) {
            // addLiquidityATP guarantees that all of amountATPV1 or amountTokenV1 will be used, hence this else is safe
            TransferHelper.safeTransferATP(msg.sender, amountATPV1 - amountATPV2);
        }
    }
}