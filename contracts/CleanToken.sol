// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniswapPair {
    function token0() external view returns (address);

    function token1() external view returns (address);
}

contract CleanToken is ERC20, ERC20Burnable, Ownable {
    uint256 public fee = 1;
    address public treasury;
    mapping(address => bool) public isValidMinter;
    mapping(address => bool) public isFeePair;

    modifier onlyMinter() {
        require(isValidMinter[msg.sender], "Caller has no minter role");
        _;
    }

    constructor(address _treasury) ERC20("CleanToken", "CLT") {
        _mint(msg.sender, 100000000000e18);
        treasury = _treasury;
    }

    function addMinter(address newMinter, bool isValid) public onlyOwner {
        isValidMinter[newMinter] = isValid;
    }

    function mint(address to, uint256 amount) public onlyMinter {
        _mint(to, amount);
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
        if (isLiquidityPool(recipient)) {
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

    function getPoolToken(
        address pool,
        string memory signature,
        function() external view returns (address) getter
    ) private returns (address token) {
        (bool success, ) = pool.call(abi.encodeWithSignature(signature));
        if (success) {
            uint32 size;
            assembly {
                size := extcodesize(pool)
            }
            if (size > 0) {
                return getter();
            }
        }
    }

    function isLiquidityPool(address recipient) public returns (bool) {
        address token0 = getPoolToken(
            recipient,
            "token0()",
            IUniswapPair(recipient).token0
        );
        address token1 = getPoolToken(
            recipient,
            "token1()",
            IUniswapPair(recipient).token1
        );

        return (isFeePair[recipient] ||
            token0 == address(this) ||
            token1 == address(this));
    }
}