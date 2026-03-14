/**
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.19;

/**
 * @title AllowList
 * @author hackFlu
 * @notice The Alowlist interface for the user.
 */
interface IAllowlist {
    /// @notice Returns reference to the allowlist that this client queries
    function allowlist() external view returns (address[] memory);

    /// @notice Sets the allowlist contract reference
    function addToAllowList(address allowedAdress) external;

    function isAllowed(address account) external view returns (bool);

    /**
     * @dev Event for when the allowlist reference is set
     *
     * @param oldAllowlist The old allowlist
     * @param newAllowlist The new allowlist
     */
    event AllowlistSet(address oldAllowlist, address newAllowlist);

    /// @notice Error for when caller attempts to set the allowlist reference
    ///         to the zero address.
    error AllowlistZeroAddress();
}
