// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import  {Script} from "forge-std/Script.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";

contract DeplySimpleStorage is Script{

    function run() external returns(SimpleStorage){
        vm.startBroadcast();

        vm.stopBroadcast();
    }
}
