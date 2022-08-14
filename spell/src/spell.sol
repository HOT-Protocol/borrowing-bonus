pragma solidity >=0.5.15;

import "lib/dss-interfaces/src/dapp/DSPauseAbstract.sol";
import "lib/dss-interfaces/src/dss/MkrAuthorityAbstract.sol";

contract SpellAction {
    function execute() external {
        address GOV_GUARD       = 0x1466b5e0D65c5CFeBD4392F1ef6517C5F37406EF;
        address BORROWING_BONUS = 0x5b278FFe5a52f17BDBDD0613b45A7a6c39473B7d;

        MkrAuthorityAbstract(GOV_GUARD).rely(BORROWING_BONUS);
    }
}

contract DssSpell {
    DSPauseAbstract public pause =
        DSPauseAbstract(0x94a94dade751dB5BD31D58A7552B5efd8e27aB46);
    address         public action;
    bytes32         public tag;
    uint256         public eta;
    bytes           public sig;
    uint256         public expiration;
    bool            public done;

    string constant public description = "Borrowing Bonus Spell Deploy";

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 30 days;
    }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}