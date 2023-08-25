import ICRC2Mock        "mocks/ICRC2Mock";
import Types            "../src/backend/interac/Types";
import Controller       "../src/backend/interac/Controller";

import { test; suite; } "mo:test/async";
import Map              "mo:map/Map";
import Fuzz             "mo:fuzz";
import Iter             "mo:base/Iter";
import Buffer           "mo:base/Buffer";
import Result           "mo:base/Result";

await suite("Controller test suite", func(): async () {
  
  await test("Nominal interac flow", func(): async () {

    type Interac = Types.Interac;
    type Fuzzer  = Fuzz.Fuzzer;

    let fuzz = Fuzz.fromSeed(0);

    let icrc2 = await ICRC2Mock.ICRC2Mock();

    let controller = Controller.Controller({ interacs = Map.new<Nat, Interac>(Map.nhash); var idx = 0; }, icrc2);

    // Arbitrary parameters
    let interac_canister = fuzz.principal.randomPrincipal(10);
    let sender = fuzz.principal.randomPrincipal(10);
    let receivers = Buffer.Buffer<Principal>(10);
    let fee = 10_000;
    let time = 0;

    // Need to initialize the controller
    icrc2.expectCall(#icrc1_fee(fee));
    await* controller.init(interac_canister);
    
    // Send 10 interacs
    for (i in Iter.range(0, 9)) {
      let receiver = fuzz.principal.randomPrincipal(10);
      receivers.add(receiver);
      let amount = fuzz.nat.randomRange(0, 1_000_000);
      let question = fuzz.text.randomAlphabetic(50);
      let password = fuzz.text.randomAlphanumeric(20);
      // Configure the call to the ledger
      icrc2.expectCall(#icrc2_transfer_from(#Ok(0)));
      assert(Result.isOk(await* controller.send(time, sender, receiver, amount, question, password)));
    };

    // Check that the sender has 10 redeemables
    let redeemables = controller.getRedeemables(sender);
    assert redeemables.size() == 10;

    // Redeem the first 5
    for (i in Iter.range(0, 4)) {
      let redeemable = redeemables.get(i);
      // Configure the call to the ledger
      icrc2.expectCall(#icrc1_transfer(#Ok(0)));
      assert(Result.isOk(await* controller.redeem(time, sender, redeemable.id)));
    };

    // Check that the sender has only 5 redeemables left
    assert controller.getRedeemables(sender).size() == 5;

    // Claim the last 5 interacs from the receivers
    for (i in Iter.range(0, receivers.size() - 1)){
      let receiver = receivers.get(i);
      let claimables = controller.getClaimables(receiver);
      if (i < 5) {
        assert claimables.size() == 0;
      } else {
        let interac = claimables[0];
        assert interac.sender == sender;
        assert interac.receiver == receiver;
        // Configure the call to the ledger
        icrc2.expectCall(#icrc1_transfer(#Ok(0)));
        assert(Result.isOk(await* controller.claim(time, receiver, interac.id, interac.answer)));
      };
    };

    // Check that the sender has no redeemable left
    assert controller.getRedeemables(sender).size() == 0;

    // Checkk that no expected calls are left
    assert not (await icrc2.hasExpectedCalls());
  });
});
