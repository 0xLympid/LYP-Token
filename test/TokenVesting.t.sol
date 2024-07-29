// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "forge-std/Test.sol";

import "../src/token/ERC677/BurnMintERC677.sol";
import "../src/vesting/TokenVesting.sol";

contract TokenVestingTest is Test {
    BurnMintERC677 public testToken;
    TokenVesting public tokenVesting;
    address public owner;
    address public treasury;
    address public addr1;
    address public addr2;

    function setUp() public {
        owner = address(this);
        treasury = address(0x123);
        addr1 = address(0x456);
        addr2 = address(0x789);

        uint8 decimals = 18;
        uint256 maxSupply = 100_000_000 * 10**decimals;
        
        testToken = new BurnMintERC677("Lympid", "LYP", decimals, maxSupply);
        tokenVesting = new TokenVesting(address(testToken));
 
        vm.prank(owner);
        // Grant mint roles
        testToken.grantMintRole(owner);
        // Transfer all tokens to treasury
        testToken.mint(treasury, testToken.maxSupply());
        vm.stopPrank();
    }

    function testCheckInputParametersForCreateVestingSchedule() public {
        vm.prank(treasury);
        testToken.transfer(address(tokenVesting), 1000 * 10**18);
        vm.stopPrank();

        vm.prank(owner);
        vm.expectRevert();
        tokenVesting.createVestingSchedule(addr1, 0, 0, 1000, false, 10000 * 10**18);
        vm.stopPrank();
        
        vm.prank(owner);
        vm.expectRevert("duration must be > 0");
        tokenVesting.createVestingSchedule(addr1, 0, 0, 0, false, 1 * 10**18);
        vm.stopPrank();

        vm.prank(owner);
        vm.expectRevert("amount must be > 0");
        tokenVesting.createVestingSchedule(addr1, 0, 0, 1000, false, 0); 
        vm.stopPrank();
    }
    
    function testComputeVestingScheduleIndex() public view {
        bytes32 expectedVestingScheduleId = keccak256(abi.encodePacked(addr1, uint256(0)));
        assertEq(tokenVesting.computeVestingScheduleIdForAddressAndIndex(addr1, 0), expectedVestingScheduleId);
        assertEq(tokenVesting.computeNextVestingScheduleIdForHolder(addr1), expectedVestingScheduleId);
    }

    function testVestWithNoCliff() public {
        // Transfer tokens from treasury to vesting contract
        vm.prank(treasury);
        testToken.transfer(address(tokenVesting), 1000 * 10**18);
        vm.stopPrank();

        assertEq(testToken.balanceOf(address(tokenVesting)), 1000 * 10**18, "Initial contract balance");

        address beneficiary = addr1;
        uint256 startTime = 0;
        uint256 cliff = 0;
        uint256 duration = 1000;
        bool revocable = true;
        uint256 amount = 100 * 10**18;

        // Create new vesting schedule
        vm.prank(owner);
        tokenVesting.createVestingSchedule(
            beneficiary,
            startTime,
            cliff,
            duration,
            revocable,
            amount
        );
        vm.stopPrank();

        assertEq(tokenVesting.getVestingSchedulesCount(), 1, "Vesting schedule count");
        assertEq(tokenVesting.getVestingSchedulesCountByBeneficiary(beneficiary), 1, "Vesting schedule count by beneficiary");

        // Compute vesting schedule id
        bytes32 vestingScheduleId = tokenVesting.computeVestingScheduleIdForAddressAndIndex(beneficiary, 0);

        // Set time to half the vesting period
        vm.warp(startTime + cliff + duration / 2);

        // Check that vested amount is half the total amount to vest
        assertEq(tokenVesting.computeReleasableAmount(vestingScheduleId), amount / 2, "Vested amount after half duration");

        // Set time to the end of the vesting period (18 months)
        vm.warp(startTime + cliff + duration);

        // Check that vested amount is equal to the total amount
        assertEq(tokenVesting.computeReleasableAmount(vestingScheduleId), amount, "Total vested amount at end");
    }

    function testVestWithCliff() public {
        // Transfer tokens to vesting contract
        vm.prank(treasury);
        testToken.transfer(address(tokenVesting), 1000 * 10**18);
        vm.stopPrank();

        address beneficiary = addr1;
        uint256 startTime = 0;
        uint256 cliff = 500;
        uint256 duration = 1000;
        bool revocable = true;
        uint256 amount = 100 * 10**18;

        // Create new vesting schedule
        vm.prank(owner);
        tokenVesting.createVestingSchedule(
            beneficiary,
            startTime,
            cliff,
            duration,
            revocable,
            amount
        );
        vm.stopPrank();

        assertEq(tokenVesting.getVestingSchedulesCount(), 1, "Vesting schedule count");
        assertEq(tokenVesting.getVestingSchedulesCountByBeneficiary(beneficiary), 1, "Vesting schedule count by beneficiary");

        // Compute vesting schedule id
        bytes32 vestingScheduleId = tokenVesting.computeVestingScheduleIdForAddressAndIndex(beneficiary, 0);

        // Check that vested amount is 0 before cliff
        assertEq(tokenVesting.computeReleasableAmount(vestingScheduleId), 0, "Initial vested amount before cliff");

        // Set time to just before the cliff
        vm.warp(startTime + cliff - 1);

        // Check that vested amount is still 0 just before the cliff
        assertEq(tokenVesting.computeReleasableAmount(vestingScheduleId), 0, "Vested amount just before cliff");

        // Set time to halfway through the vesting period
        vm.warp(startTime + cliff + (duration - cliff) / 2);

        // Check that the vested amount is half of the total amount
        assertEq(tokenVesting.computeReleasableAmount(vestingScheduleId), amount / 2, "Vested amount in middle of vesting period");

        // Set time to the end of the vesting period (18 months)
        vm.warp(startTime + duration);

        // Check that vested amount is equal to the total amount
        assertEq(tokenVesting.computeReleasableAmount(vestingScheduleId), amount, "Total vested amount at end");
    }

    function testOwnerReleaseVestedTokens() public {
        // Transfer tokens from treasury to vesting contract
        vm.prank(treasury);
        testToken.transfer(address(tokenVesting), 1000 * 10**18);
        vm.stopPrank();

        assertEq(testToken.balanceOf(address(tokenVesting)), 1000 * 10**18, "Initial contract balance");

        address beneficiary = addr1;
        uint256 startTime = 0;
        uint256 cliff = 0;
        uint256 duration = 1000;
        bool revocable = true;
        uint256 amount = 100 * 10**18;

        // Create new vesting schedule
        vm.prank(owner);
        tokenVesting.createVestingSchedule(
            beneficiary,
            startTime,
            cliff,
            duration,
            revocable,
            amount
        );
        vm.stopPrank();

        assertEq(tokenVesting.getVestingSchedulesCount(), 1, "Vesting schedule count");
        assertEq(tokenVesting.getVestingSchedulesCountByBeneficiary(beneficiary), 1, "Vesting schedule count by beneficiary");

        // Compute vesting schedule id
        bytes32 vestingScheduleId = tokenVesting.computeVestingScheduleIdForAddressAndIndex(beneficiary, 0);

        // Set current time after the end of the vesting period
        vm.warp(startTime + cliff + duration + 1);

        // Check that the vested amount is 100
        assertEq(tokenVesting.computeReleasableAmount(vestingScheduleId), amount, "Vested amount after full duration");

        // Owner release vested tokens
        vm.prank(owner);
        tokenVesting.release(vestingScheduleId, amount);
        vm.stopPrank();
       
        TokenVesting.VestingSchedule memory vestingSchedule = tokenVesting.getVestingSchedule(vestingScheduleId);
        // Check that the number of released tokens is 100
        assertEq(vestingSchedule.released, amount, "Total released amount");

        // Check that the vested amount is 0
        assertEq(tokenVesting.computeReleasableAmount(vestingScheduleId), 0, "Final vested amount");
    }
    
    function testBeneficiaryReleaseVestedTokens() public {
        // Transfer tokens from treasury to vesting contract
        vm.prank(treasury);
        testToken.transfer(address(tokenVesting), 1000 * 10**18);
        vm.stopPrank();

        assertEq(testToken.balanceOf(address(tokenVesting)), 1000 * 10**18, "Initial contract balance");

        address beneficiary = addr1;
        uint256 startTime = 0;
        uint256 cliff = 0;
        uint256 duration = 1000;
        bool revocable = true;
        uint256 amount = 100 * 10**18;

        // Create new vesting schedule
        vm.prank(owner);
        tokenVesting.createVestingSchedule(
            beneficiary,
            startTime,
            cliff,
            duration,
            revocable,
            amount
        );
        vm.stopPrank();

        assertEq(tokenVesting.getVestingSchedulesCount(), 1, "Vesting schedule count");
        assertEq(tokenVesting.getVestingSchedulesCountByBeneficiary(beneficiary), 1, "Vesting schedule count by beneficiary");

        // Compute vesting schedule id
        bytes32 vestingScheduleId = tokenVesting.computeVestingScheduleIdForAddressAndIndex(beneficiary, 0);

        // Set current time after the end of the vesting period
        vm.warp(startTime + cliff + duration + 1);

        // Check that the vested amount is 100
        assertEq(tokenVesting.computeReleasableAmount(vestingScheduleId), amount, "Vested amount after full duration");

        // Owner release vested tokens (45)
        vm.prank(beneficiary);
        tokenVesting.release(vestingScheduleId, amount);
        vm.stopPrank();
       
        TokenVesting.VestingSchedule memory vestingSchedule = tokenVesting.getVestingSchedule(vestingScheduleId);
        // Check that the number of released tokens is 100
        assertEq(vestingSchedule.released, amount, "Total released amount");

        // Check that the vested amount is 0
        assertEq(tokenVesting.computeReleasableAmount(vestingScheduleId), 0, "Final vested amount");
    }

    function testReleaseVestedTokensIfRevoked() public {
        // Transfer tokens to vesting contract
        vm.prank(treasury);
        testToken.transfer(address(tokenVesting), 1000 * 10**18);
        vm.stopPrank();

        address beneficiary = addr1;
        uint256 startTime = 0;
        uint256 cliff = 0;
        uint256 duration = 1000;
        bool revocable = true;
        uint256 amount = 100 * 10**18;

        // Create new vesting schedule
        vm.prank(owner);
        tokenVesting.createVestingSchedule(
            beneficiary,
            startTime,
            cliff,
            duration,
            revocable,
            amount
        );
        vm.stopPrank();

        // Compute vesting schedule id
        bytes32 vestingScheduleId = tokenVesting.computeVestingScheduleIdForAddressAndIndex(beneficiary, 0);

        // Set time to half the vesting period
        vm.warp(startTime + cliff + duration / 2);

        // Revoke vesting schedule and check event
        vm.prank(owner);
        tokenVesting.revoke(vestingScheduleId);
        vm.stopPrank();

        // Check that the vesting schedule has been revoked and that the vested amount was released
        TokenVesting.VestingSchedule memory vestingSchedule = tokenVesting.getVestingSchedule(vestingScheduleId);
        assert(vestingSchedule.revoked);
        assertEq(vestingSchedule.released, amount / 2, "Released amount after revoke");
    }

    function testWithdrawTokens() public {
        vm.prank(treasury);
        testToken.transfer(address(tokenVesting), 1000 * 10**18);
        vm.stopPrank();

        // Owner should be able to withdraw tokens
        vm.prank(owner);
        tokenVesting.withdraw(500 * 10**18);
        vm.stopPrank();

        assertEq(testToken.balanceOf(owner), 500 * 10**18, "Owner balance after withdrawal");
        assertEq(testToken.balanceOf(address(tokenVesting)), 500 * 10**18, "Contract balance after withdrawal");
        
        // Non-owner should not be able to withdraw tokens
        vm.prank(addr1);
        vm.expectRevert();
        tokenVesting.withdraw(100 * 10**18);
        vm.stopPrank();
    }

    function testWithdrawMoreThanAvailable() public {
        vm.prank(treasury);
        testToken.transfer(address(tokenVesting), 1000 * 10**18);
        vm.stopPrank();

        vm.prank(owner);
        vm.expectRevert();
        tokenVesting.withdraw(1500 * 10**18);
        vm.stopPrank();
    }
}
