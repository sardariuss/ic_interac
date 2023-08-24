import Types     "Types";

import Map       "mo:map/Map";
import Debug     "mo:base/Debug";
import Principal "mo:base/Principal";
import Array     "mo:base/Array";

module {

  type Register  = Types.Register;
  type Interac   = Types.Interac;
  type Map<K, V> = Map.Map<K, V>;

  public class Controller(_register: Register) {
    
    public func send(caller: Principal, receiver: Principal, amount: Nat, question: Text, answer: Text) : async* () {

      if (Principal.isAnonymous(caller)){
        Debug.trap("Cannot anonymously send an interac");
      };

      if (Principal.isAnonymous(caller)){
        Debug.trap("Cannot send an interac to an anonymous principal");
      };

      if (caller == receiver){
        Debug.trap("Cannot send an interac to yourself");
      };
      
      // Create the interac
      let interac = { id = _register.idx; sender = caller; receiver; amount; question; answer; };
      Map.set(_register.interacs, Map.nhash, interac.id, interac);
      _register.idx += 1;
    };

    public func redeem(caller: Principal, id: Nat) : async* () {
      switch(Map.get(_register.interacs, Map.nhash, id)) {
        case(null) { Debug.trap("Interac not found"); };
        case(?interac) {
          if (interac.sender != caller) {
            Debug.trap("You are not the sender of this interac");
          };
          Map.delete(_register.interacs, Map.nhash, id);
        };
      };
    };

    public func claim(caller: Principal, id: Nat, answer: Text) : async* () {
      switch(Map.get(_register.interacs, Map.nhash, id)) {
        case(null) { Debug.trap("Interac not found"); };
        case(?interac) {
          if (interac.receiver != caller) {
            Debug.trap("You are not the receiver of this interac");
          };
          if (interac.answer != answer) {
            Debug.trap("Wrong answer");
          };
          Map.delete(_register.interacs, Map.nhash, id);
        };
      };
    };

    public func getRedeemables(caller: Principal) : [Interac] {
      Map.toArrayMap(_register.interacs, func(id: Nat, interac: Interac) : ?Interac { 
        if (interac.sender == caller) { ?interac; } else { null; };
      });
    };

    public func getClaimables(caller: Principal) : [Interac] {
      Map.toArrayMap(_register.interacs, func(id: Nat, interac: Interac) : ?Interac { 
        if (interac.receiver == caller) { ?interac; } else { null; };
      });
    };
  };

};