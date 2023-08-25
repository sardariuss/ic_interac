import Types       "Types";
import Controller  "Controller";

import Map         "mo:map/Map";

import Principal   "mo:base/Principal";
import Time        "mo:base/Time";

import Token       "canister:token";

shared actor class Interac() = _this {

  type Interac      = Types.Interac;
  type Register     = Types.Register;
  type SendResult   = Types.SendResult;
  type RedeemResult = Types.RedeemResult;
  type ClaimResult  = Types.ClaimResult;

  stable let _register = {
    interacs = Map.new<Nat, Interac>(Map.nhash);
    var idx = 0;
  };

  let _controller = Controller.Controller(_register, Token);

  public shared func init() : async () {
    await* _controller.init(Principal.fromActor(_this));
  };

  public shared({caller}) func send(receiver: Principal, amount: Nat, question: Text, answer: Text) : async SendResult {
    await* _controller.send(Time.now(), caller, receiver, amount, question, answer);
  };

  public shared({caller}) func redeem(id: Nat) : async RedeemResult {
    await* _controller.redeem(Time.now(), caller, id);
  };

  public shared({caller}) func claim(id: Nat, answer: Text) : async ClaimResult {
    await* _controller.claim(Time.now(), caller, id, answer);
  };

  public query({caller}) func getRedeemables() : async [Interac] {
    _controller.getRedeemables(caller);
  };

  public query({caller}) func getClaimables() : async [Interac] {
    _controller.getClaimables(caller);
  };

};
