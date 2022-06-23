// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "../contracts/SmartBond.sol";
import "truffle/Assert.sol";

contract SmartBondTest {
    SmartBond liberoSmartBond;
    Ownable OwnableTest;

    receive() external payable {}

    constructor() {
        liberoSmartBond = new SmartBond("Libero", 1, 18, 1, 1, 0, 1, address(0xFec392641a06e3858984304B60046542FaB1E522), 1000);
    }

    function testChangeLoopLimit() public {
        uint _loopLimit = 1000;
        Assert.isAbove(_loopLimit, uint(0), "_loopLimit should be greater than to 0");
        liberoSmartBond.changeLoopLimit(_loopLimit);
    }

    function testMintBond() public {
        uint _bondsAmount = 3;
        
        Assert.notEqual(address(this), address(0), "buyer don`t must be address(0)");
        Assert.isAtLeast(_bondsAmount, uint(1), "_bondsAmount should be greater than to 1");
        Assert.isAtLeast(liberoSmartBond.loopLimit(), _bondsAmount, "loopLimit should be greater than to _bondsAmount");

        liberoSmartBond.mintBond(address(this), _bondsAmount);
    }

    function testRedeemCoupons() public {
        uint256[] memory _bonds = new uint256[](2);
        _bonds[0] = 1;
        _bonds[1] = 1;

        Assert.isAbove(_bonds.length, uint(0), "_bonds.length should be greater than to 0");
        Assert.isAtLeast(liberoSmartBond.loopLimit(), _bonds.length, "_bonds.length should be greater than to 0");
        Assert.isAbove(liberoSmartBond.getBalance(address(this)), _bonds.length, "amount___________________________________");

        liberoSmartBond.redeemCoupons(_bonds);
    }

    function testTransfer() public {
        uint256[] memory _bonds = new uint256[](2);
        _bonds[0] = 1;
        _bonds[1] = 1;

        Assert.isAbove(_bonds.length, uint(0), "_bonds.length should be greater than to 0");
        Assert.notEqual(address(this), address(0), "receiver don`t must be address(0)");

        liberoSmartBond.transfer(address(this), _bonds);
    }
}