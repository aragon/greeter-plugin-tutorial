![Aragon](https://res.cloudinary.com/dacofvu8m/image/upload/v1677638385/Aragon%20CodeArena/aragon-logo-navy_gyr2qt.png)

# How to build an AragonOSx Non-Upgradeable Plugin

In this tutorial, we will build an AragonOSx Non-Upgradeable plugin.

We will build a basic `GreeterPlugin` which returns "Hello world!".

## Setup

1. Make sure you have Node.js in your computer.

For Mac:
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
nvm install 18
nvm use 18
nvm alias default 18
npm install npm --global
```

Or for Linux:
```bash
sudo apt update
sudo apt install curl git
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

[Here's a tutorial](https://hardhat.org/tutorial/setting-up-the-environment) on installing this if you haven't done so already.

2. Next up, we want to create a Hardhat project in our terminal. This is the Solidity framework we'll use to get our project up and runing.

```bash
npm init
npm install --save-dev hardhat
npx hardhat
```

[Here's a tutorial](https://hardhat.org/tutorial/creating-a-new-hardhat-project) on how to answer the prompts if you need. For reference, I used the Typescript option for my Hardhat project.

3. Install `@aragon/osx` package

We want to install the Aragon OSx contract package within our project so we can access and import them throughout our project. This should speed up development significantly, although not it's not mandatory in order to build Aragon plugins.

```bash
npm i @aragon/osx
```

## Building the plugin

1. Create `GreeterPlugin` contract

Plugins are composed of two key contracts:
- The `Plugin` contract, containing the implementation logic for the Plugin,
- The `PluginSetup` contract, containing the instructions needed to install or uninstall a Plugin into a DAO.

In this case, we will create the `GreeterPlugin.sol` contract containing the main logic for our plugin - aka returning "Hello world!" when calling on the `greet()` function. Keep in mind, that because we're importing from the `Plugin` base template in this case, we are able to tap into:
- the `auth(PERMISSION_ID)` modifier, which checks whether the account calling on that function has the permission specified in the `auth` parameters.
- the `dao()` getter function, which returns the DAO instance for the plugin.

First, in your terminal, create the `GreeterPlugin.sol` contract:

```bash
touch contracts/GreeterPlugin.sol
```

Then, inside of the file, add the functionality:

```solidity
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

import {Plugin, IDAO} from "@aragon/osx/core/plugin/Plugin.sol";

contract GreeterPlugin is Plugin {
  // Permissions are what connects everything together. Addresses who have been granted the GREET_PERMISSION will be able to call on functions with the modifier `auth(GREET_PERMISSION_ID)`. These will be granted in the PluginSetup.sol contract up next.
  bytes32 public constant GREET_PERMISSION_ID = keccak256("GREET_PERMISSION");

  constructor(IDAO _dao) Plugin(_dao) {}

  function greet() external view auth(GREET_PERMISSION_ID) returns (string memory) {
    return "Hello, world!";
  }
}
```

2. Create `GreeterPluginSetup` contract

Now that we're done with our `GreeterPlugin` implementation, we can get started with the installation instructions.

When we speak of installation, we're essentially referring to the the granting of the permissions needed so that the transactions can happen. In our `GreeterPlugin` contract, we defined a `GREET_PERMISSION`. Then, we used the `auth(GREET_PERMISSION_ID)` modifier on the `greet()`, defining that only those addresses with the `GREET_PERMISSION` will be able to call on the `greet()` function.

In the `prepareInstallation()` function here then, we will grant the `GREET_PERMISSION` to the DAO so it can call the function. In the `prepareUninstallation()` function, we do the opposite and revoke the `GREET_PERMISSION`.

```solidity
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

import {PluginSetup} from '@aragon/osx/framework/plugin/setup/PluginSetup.sol';
import {PermissionLib} from '@aragon/osx/core/permission/PermissionLib.sol';
import './GreeterPlugin.sol';

contract GreeterPluginSetup is PluginSetup {
  function prepareInstallation(
    address _dao,
    bytes memory
  ) external returns (address plugin, PreparedSetupData memory preparedSetupData) {
    plugin = address(new GreeterPlugin(IDAO(_dao)));

    PermissionLib.MultiTargetPermission[] memory permissions = new PermissionLib.MultiTargetPermission[](1);

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
  ) external pure returns (PermissionLib.MultiTargetPermission[] memory permissions) {
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
```

## Deploy your Plugin in Hardhat's local environment

1. In the Terminal, we first want to create a deployment script file:

```bash
touch scripts/deploy.ts
```

2. Now, let's add the deployment script in to the `deploy.ts` file

```solidity
import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const getGreeterSetup = await ethers.getContractFactory("GreeterPluginSetup");
  const GreeterSetup = await getGreeterSetup.deploy();

  await GreeterSetup.deployed();

  console.log("GreeterSetup address:", GreeterSetup.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
```

3. Let's deploy!

In your terminal, run:

```bash
npx hardhat run scripts/deploy.ts
```

## Deploy Plugin to Goerli

Now that we know the local deployment works, we will want to deploy our pugin to Goerli testnet so we can publish it in the Aragon OSx protocol to be accessed by DAOs.

1. Firstly, let's set up the `hardhat.config.js` with Goerli environment attributes

```tsx
import "@nomicfoundation/hardhat-toolbox";

// To find your Alchemy key, go to https://dashboard.alchemy.com/. Infure or any other provider would work here as well.
const goerliAlchemyKey = "add-your-own-alchemy-key";
// To find a private key, go to your wallet of choice and export a private key. Remember this must be kept secret at all times.
const privateKeyGoerli = "add-your-account-private-key";

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
    },
    goerli: {
      url: `https://eth-goerli.g.alchemy.com/v2/${goerliAlchemyKey}`,
      accounts: [privateKeyGoerli]
    }
  },
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 40000
  }
};
```

2. Once we have the Goerli environment set up, run this command in your terminal to deploy the plugin:

```bash
npx hardhat run --network goerli scripts/deploy.ts
```

## Publish the Plugin in Aragon OSx

Now that the plugin is deployed on Goerli, we can publish it into the Aragon OSx Protocol so any DAO can install it! 

Publishing a plugin into Aragon OSx means creating a `PluginRepo` instance containing the plugin's first version. As developers can deploy more versions of the plugin moving forward, publishing a new version means adding a new `PluginSetup` contract into the this `PluginRepo` will contain all plugin versions

You can do that through a few different ways:

### a) Etherscan

Go to the [`PluginFactory`](https://goerli.etherscan.io/address/0x301868712b77744A3C0E5511609238399f0A2d4d#writeContract) contract on Etherscan and deploy the first version of your plugin.

![Register your Plugin through Etherscan](https://res.cloudinary.com/dacofvu8m/image/upload/v1682466427/Screen_Shot_2023-04-25_at_19.46.58_nlo9p1.png)

### b) Publishing script

You can also publish your Plugin through using a `publish` script.

1. Create the `publish.ts` file within your `scripts` folder.

```bash
touch scripts/publish.ts
```

2. Add this publishing script to the `publish.ts` file. 
 
This will get the `PluginRepoFactory` contract and call on its `createPluginRepoWithFirstVersion` to create the plugin's `PluginRepo` instance, where plugin versions will be stored.

```ts
import {
  PluginRepoFactory__factory,
  PluginRepoRegistry__factory,
  PluginRepo__factory,
} from '@aragon/osx-ethers';
import {DeployFunction} from 'hardhat-deploy/types';
import {HardhatRuntimeEnvironment} from 'hardhat/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {deployments, network} = hre;
  const [deployer] = await hre.ethers.getSigners();
  
  const pluginRepoFactoryAddr = '0x301868712b77744A3C0E5511609238399f0A2d4d';

  const pluginRepoFactory = PluginRepoFactory__factory.connect(
    pluginRepoFactoryAddr,
    deployer
  );

  const pluginName = 'greeter-plugin';
  const pluginSetupContractName = 'GreeterPluginSetup';

  const pluginSetupContract = await deployments.get(pluginSetupContractName);

  const tx = await pluginRepoFactory.createPluginRepoWithFirstVersion(
    pluginName,
    pluginSetupContract.address,
    deployer.address,
    '0x00',
    '0x00'
  );

  console.log(`You can find the transaction address which published the ${pluginName} Plugin here: ${tx}`);
};

export default func;
```

In order to run the script and finalize the publishing, run this in your terminal:

```bash
npx hardhat run scripts/publish.ts
```

### Testing

4. Make sure it works by calling on the `getPlugins()` query in our [subgraph](https://subgraph.satsuma-prod.com/aragon/osx-goerli/playground) and hit "Play".

```graphql
query GetPlugins {
  pluginRepos {
      subdomain
    }
}
```

This should return a list of all plugins deployed to the Aragon protocol, including yours.

## Conclusion

Hope this tutorial is useful to get you started developing for Aragon! If you need any additional support or questions, feel free to hop into our [Discord](https://discord.gg/Wpk36QRdMN) and ask away.

Excited to see what you build! 🔥
