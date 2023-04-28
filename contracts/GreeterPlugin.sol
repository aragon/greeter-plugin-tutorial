// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

import { Plugin, IDAO } from "@aragon/osx/core/plugin/Plugin.sol";

contract GreeterPlugin is Plugin {
    bytes32 public constant GREET_PERMISSION_ID = keccak256("GREET_PERMISSION");

    constructor(IDAO _dao) Plugin(_dao) {}

    function greet()
        external
        view
        auth(GREET_PERMISSION_ID)
        returns (string memory)
    {
        return "Hello World";
    }
}
