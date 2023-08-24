import Types            "../src/backend/Types";
import Controller       "../src/backend/Controller";

import { test; suite; } "mo:test/async";
import Map              "mo:map/Map";
import Fuzz             "mo:fuzz";
import Iter             "mo:base/Iter";
import Buffer           "mo:base/Buffer";

await suite("Controller suite", func(): async () {
  
  await test("Basic interac flow", func(): async () {

    type Interac = Types.Interac;
    type Fuzzer  = Fuzz.Fuzzer;

    let fuzz = Fuzz.fromSeed(0);

    let controller = Controller.Controller({ interacs = Map.new<Nat, Interac>(Map.nhash); var idx = 0; });

    let sender = fuzz.principal.randomPrincipal(10);
    let receivers = Buffer.Buffer<Principal>(10);

    // Send 10 interacs
    for (i in Iter.range(1, 10)) {
      let receiver = fuzz.principal.randomPrincipal(10);
      receivers.add(receiver);
      let amount = fuzz.nat.randomRange(0, 1_000_000);
      let question = fuzz.text.randomAlphabetic(50);
      let password = fuzz.text.randomAlphanumeric(20);
      await* controller.send(sender, receiver, amount, question, password);
    };

    // Check that the sender has 10 redeemables
    let redeemables = controller.getRedeemables(sender);
    assert redeemables.size() == 10;

    // Redeem the first 5
    for (i in Iter.range(0, 4)) {
      let redeemable = redeemables.get(i);
      await* controller.redeem(sender, redeemable.id);
    };

    // Claim the last 5
    for (i in Iter.range(0, receivers.size() - 1)){
      let receiver = receivers.get(i);
      let claimables = controller.getClaimables(receiver);
      if (i < 5) {
        assert claimables.size() == 0;
      } else {
        assert claimables.size() == 1;
        assert claimables[0].sender == sender;
        assert claimables[0].receiver == receiver;
      };
    };

  });
});
