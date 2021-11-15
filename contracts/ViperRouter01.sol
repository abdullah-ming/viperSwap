// pragma solidity ^0.6.6;
pragma solidity ^0.5.16;

import './interfaces/IViperFactory.sol';
import './libraries/TransferHelper.sol';
import './libraries/ViperLibrary.sol';
import './interfaces/IViperRouter01.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWATP.sol';

contract ViperRouter01 is IViperRouter01 {
    address public factory;
    address public WATP;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'ViperRouter: EXPIRED');
        _;
    }

    constructor(address _factory, address _WATP) public {
        factory = _factory;
        WATP = _WATP;
    }

    function() external payable {
        assert(msg.sender == WATP); // only accept ATP via fallback from the WATP contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) private returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IViperFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IViperFactory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = ViperLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = ViperLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'ViperRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = ViperLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'ViperRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = ViperLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IViperPair(pair).mint(to);
    }
    function addLiquidityATP(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountATPMin,
        address to,
        uint deadline
    ) external payable ensure(deadline) returns (uint amountToken, uint amountATP, uint liquidity) {
        (amountToken, amountATP) = _addLiquidity(
            token,
            WATP,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountATPMin
        );
        address pair = ViperLibrary.pairFor(factory, token, WATP);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWATP(WATP).deposit.value(amountATP)();
        assert(IWATP(WATP).transfer(pair, amountATP));
        liquidity = IViperPair(pair).mint(to);
        if (msg.value > amountATP) TransferHelper.safeTransferATP(msg.sender, msg.value - amountATP); // refund dust ATP, if any
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = ViperLibrary.pairFor(factory, tokenA, tokenB);
        IViperPair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IViperPair(pair).burn(to);
        (address token0,) = ViperLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'ViperRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'ViperRouter: INSUFFICIENT_B_AMOUNT');
    }
    function removeLiquidityATP(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountATPMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountToken, uint amountATP) {
        (amountToken, amountATP) = removeLiquidity(
            token,
            WATP,
            liquidity,
            amountTokenMin,
            amountATPMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWATP(WATP).withdraw(amountATP);
        TransferHelper.safeTransferATP(to, amountATP);
    }
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB) {
        address pair = ViperLibrary.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? uint(-1) : liquidity;
        IViperPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
    function removeLiquidityATPWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountATPMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountATP) {
        address pair = ViperLibrary.pairFor(factory, token, WATP);
        uint value = approveMax ? uint(-1) : liquidity;
        IViperPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountATP) = removeLiquidityATP(token, liquidity, amountTokenMin, amountATPMin, to, deadline);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) private {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = ViperLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? ViperLibrary.pairFor(factory, output, path[i + 2]) : _to;
            IViperPair(ViperLibrary.pairFor(factory, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory amounts) {
        amounts = ViperLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'ViperRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(path[0], msg.sender, ViperLibrary.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory amounts) {
        amounts = ViperLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'ViperRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(path[0], msg.sender, ViperLibrary.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
    }
    function swapExactATPForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WATP, 'ViperRouter: INVALID_PATH');
        amounts = ViperLibrary.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'ViperRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWATP(WATP).deposit.value(amounts[0])();
        assert(IWATP(WATP).transfer(ViperLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    function swapTokensForExactATP(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WATP, 'ViperRouter: INVALID_PATH');
        amounts = ViperLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'ViperRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(path[0], msg.sender, ViperLibrary.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, address(this));
        IWATP(WATP).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferATP(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForATP(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WATP, 'ViperRouter: INVALID_PATH');
        amounts = ViperLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'ViperRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(path[0], msg.sender, ViperLibrary.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, address(this));
        IWATP(WATP).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferATP(to, amounts[amounts.length - 1]);
    }
    function swapATPForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WATP, 'ViperRouter: INVALID_PATH');
        amounts = ViperLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'ViperRouter: EXCESSIVE_INPUT_AMOUNT');
        IWATP(WATP).deposit.value(amounts[0])();
        assert(IWATP(WATP).transfer(ViperLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        if (msg.value > amounts[0]) TransferHelper.safeTransferATP(msg.sender, msg.value - amounts[0]); // refund dust ATP, if any
    }

    function quote(uint amountA, uint reserveA, uint reserveB) public pure returns (uint amountB) {
        return ViperLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        return ViperLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) public pure returns (uint amountIn) {
        return ViperLibrary.getAmountOut(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path) public view returns (uint[] memory amounts) {
        return ViperLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path) public view returns (uint[] memory amounts) {
        return ViperLibrary.getAmountsIn(factory, amountOut, path);
    }
}