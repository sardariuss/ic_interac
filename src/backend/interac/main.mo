import Types       "Types";
import Controller  "Controller";

import Map         "mo:map/Map";

import Principal   "mo:base/Principal";
import Time        "mo:base/Time";

import Token       "canister:token";

shared actor class Interac() = this {

  type Interac  = Types.Interac;
  type Register = Types.Register;

  stable let _register = {
    interacs = Map.new<Nat, Interac>(Map.nhash);
    var idx = 0;
  };

  let _controller = Controller.Controller(_register, Token);

  public shared({caller}) func send(receiver: Principal, amount: Nat, question: Text, answer: Text) : async() {
    await* _controller.send(Time.now(), Principal.fromActor(this), caller, receiver, amount, question, answer);
  };

  public shared({caller}) func redeem(id: Nat) : async() {
    await* _controller.redeem(Time.now(), Principal.fromActor(this), caller, id);
  };

  public shared({caller}) func claim(id: Nat, answer: Text) : async() {
    await* _controller.claim(Time.now(), Principal.fromActor(this), caller, id, answer);
  };

  public query({caller}) func getRedeemables() : async [Interac] {
    _controller.getRedeemables(caller);
  };

  public query({caller}) func getClaimables() : async [Interac] {
    _controller.getClaimables(caller);
  };

};
