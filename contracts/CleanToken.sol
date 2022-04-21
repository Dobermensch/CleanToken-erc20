// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract CleanToken is ERC20, ERC20Burnable, Ownable {
    uint256 public fee = 1;
    address public treasury;
    mapping(address => bool) public isFeePair;
    IUniswapV2Factory constant v2Factory = IUniswapV2Factory(address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f));

    constructor(address _treasury) ERC20("CleanToken", "CLT") {
        _mint(msg.sender, 100000000000e18);
        treasury = _treasury;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transferWithFee(sender, recipient, amount);

        uint256 currentAllowance = allowance(sender, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transferWithFee(_msgSender(), recipient, amount);
        return true;
    }

    function _transferWithFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (isUniswapV2Pair(recipient)) {
            uint256 burnAmount = (amount * fee) / 100;
            uint256 feeAmount = (amount * fee) / 100;
            _transfer(sender, recipient, amount - (burnAmount + feeAmount));
            _burn(sender, burnAmount);
            _transfer(sender, treasury, feeAmount);
        } else {
            _transfer(sender, recipient, amount);
        }

        return true;
    }

    function isUniswapV2Pair(address target) public view returns (bool) {
        if (target.code.length == 0) {
            return false;
        }

        IUniswapV2Pair pairContract = IUniswapV2Pair(target);

        address token0;
        address token1;

        try pairContract.token0() returns (address _token0) {
            token0 = _token0;
        } catch (bytes memory) {
            return false;
        }

        try pairContract.token1() returns (address _token1) {
            token1 = _token1;
        } catch (bytes memory) {
            return false;
        }

        return target == v2Factory.getPair(token0, token1);
    }
}