// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

import { PluginSetup } from "@aragon/osx/framework/plugin/setup/PluginSetup.sol";
import { PermissionLib } from "@aragon/osx/core/permission/PermissionLib.sol";
import "./GreeterPlugin.sol";

contract GreeterPluginSetup is PluginSetup {
    function prepareInstallation(
        address _dao,
        bytes memory
    )
        external
        returns (address plugin, PreparedSetupData memory preparedSetupData)
    {
        plugin = address(new GreeterPlugin(IDAO(_dao)));

        PermissionLib.MultiTargetPermission[]
            memory permissions = new PermissionLib.MultiTargetPermission[](1);

        permissions[0] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Grant,
            where: plugin,
            who: _dao,
            condition: PermissionLib.NO_CONDITION,
            permissionId: keccak256("GREET_PERMISSION")
        });

        preparedSetupData.permissions = permissions;
    }

    function prepareUninstallation(
        address _dao,
        SetupPayload calldata _payload
    )
        external
        pure
        returns (PermissionLib.MultiTargetPermission[] memory permissions)
    {
        permissions = new PermissionLib.MultiTargetPermission[](1);

        permissions[0] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Revoke,
            where: _payload.plugin,
            who: _dao,
            condition: PermissionLib.NO_CONDITION,
            permissionId: keccak256("GREET_PERMISSION")
        });
    }

    function implementation() external view returns (address) {}
}
