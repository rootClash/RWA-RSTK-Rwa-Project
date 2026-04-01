// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20Pausable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {IRWAAccessControl} from "../../access/IRWAAccessControl.sol";

contract RSTKToken is ERC20Pausable {
    /*//////////////////////////////////////////////////////////////
                             STATE VARIABLE
    //////////////////////////////////////////////////////////////*/
    IRWAAccessControl private immutable i_accessControl;
    uint256 token_supply = 0;
    /*//////////////////////////////////////////////////////////////
                                  ERROR
    //////////////////////////////////////////////////////////////*/
    error RSTKToken__NotPauserAdmin(address caller);
    error RSTKToken__NotAuthorized(address);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address _rwaAccessControl) ERC20("RSTKToken", "RSTK") {
        i_accessControl = IRWAAccessControl(_rwaAccessControl);
    }

    function mint(address to, uint256 amount) public {
        require(i_accessControl.isMinter(msg.sender), "Not Authorized To mint");
        token_supply += amount;
        _mint(to, amount);
    }

    function burn(address account, uint256 amount) public {
        require(i_accessControl.isBurner(msg.sender), "Not Authorized To burn");
        token_supply -= amount;
        _burn(account, amount);
    }

    function pause() public {
        require(i_accessControl.isPauser(msg.sender), "Not Authorized To pause");

        _pause();
    }

    function unpause() public {
        require(i_accessControl.isPauser(msg.sender), "Not Authorized to unpause");
        _unpause();
    }

    function totalSupply() public view override returns (uint256) {
        return token_supply;
    }
}
