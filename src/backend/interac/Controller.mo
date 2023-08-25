import Types     "Types";
import Utils     "../utils/Utils";

import Map       "mo:map/Map";
import Debug     "mo:base/Debug";
import Principal "mo:base/Principal";
import Array     "mo:base/Array";

import ICRC2     "mo:icrc2/ICRC2";

module {

  type Register       = Types.Register;
  type Interac        = Types.Interac;
  type Map<K, V>      = Map.Map<K, V>;
  type Time           = Int;
  type ICRC2Interface = ICRC2.FullInterface;

  public class Controller(_register: Register, _icrc2: ICRC2Interface) {

    let _fee = 10_000; // @todo: remove hardcoded fee
    
    public func send(time: Time, self: Principal, caller: Principal, receiver: Principal, amount: Nat, question: Text, answer: Text) : async* () {

      if (Principal.isAnonymous(caller)){
        Debug.trap("Cannot anonymously send an interac");
      };

      if (Principal.isAnonymous(caller)){
        Debug.trap("Cannot send an interac to an anonymous principal");
      };

      if (caller == receiver){
        Debug.trap("Cannot send an interac to yourself");
      };

      // Create a new interac
      let interac = { id = _register.idx; sender = caller; receiver; amount; question; answer; };

      // Create a new subaccount with the interac's id
      let subaccount = Utils.getSubaccount(_register.idx);

      // Need to increment the index before performing the transfer
      // otherwise there is a risk that during the async, another call
      // to send will be made and the same index will be used twice
      _register.idx += 1;

      // Transfer the money from the sender to the interac subaccount
      let transfer = await _icrc2.icrc2_transfer_from({
        spender_subaccount = null; // @todo: this is not part of the ICRC2 standard, it seems to be a mistake in the lib
        from = {
          owner = caller;
          subaccount = null; // @todo: need to support subaccount
        };
        to = {
          owner = self;
          subaccount = ?subaccount;
        };
        amount = amount + _fee; // Need to add an additional the fee for the later transfer (claim or redeem)
        created_at_time = ?Utils.timeToNat64(time);
        fee = ?_fee; // @todo: null is supposed to work according to the token standard, but it doesn't...
        memo = null;
      });

      // Return an error if the transfer failed
      switch(transfer){
        case(#Err(err)) { Debug.trap("Transfer failed"); };
        case(#Ok(tx)) {};
      };
      
      // Finally add the interac to the map
      // @todo: store the transaction id inside the interac, probably need to store the redeem/claim tx too,
      // but then it requires to keep the processed interac in the map
      Map.set(_register.interacs, Map.nhash, interac.id, interac);
    };

    public func redeem(time: Time, self: Principal, caller: Principal, id: Nat) : async* () {
      
      // Get the interac from the map
      let {sender; amount} = switch(Map.get(_register.interacs, Map.nhash, id)) {
        case(null) { Debug.trap("Interac not found"); };
        case(?interac) { interac; }
      };

      if (sender != caller) {
        Debug.trap("You are not the sender of this interac");
      };

      // Transfer the money back to the sender
      let transfer = await _icrc2.icrc1_transfer({
        amount;
        created_at_time = ?Utils.timeToNat64(time);
        fee = ?_fee; // @todo: null is supposed to work according to the token standard, but it doesn't...
        from_subaccount = ?Utils.getSubaccount(id);
        memo = null;
        to = {
          owner = sender;
          subaccount = null; // @todo: need to support subaccount
        };
      });

      // Return an error if the transfer failed
      switch(transfer){
        case(#Err(err)) { Debug.trap("Transfer failed"); };
        case(#Ok(tx)) {};
      };

      // Remove the interac from the map
      Map.delete(_register.interacs, Map.nhash, id);
    };

    public func claim(time: Time, self: Principal, caller: Principal, id: Nat, proposed_answer: Text) : async* () {

      // Get the interac from the map
      let {receiver; answer; amount} = switch(Map.get(_register.interacs, Map.nhash, id)) {
        case(null) { Debug.trap("Interac not found"); };
        case(?interac) { interac; }
      };
      
      if (receiver != caller) {
        Debug.trap("You are not the receiver of this interac");
      };

      if (proposed_answer != answer) {
        Debug.trap("Wrong answer");
      };

      // Transfer the money to the receiver
      let transfer = await _icrc2.icrc1_transfer({
        amount;
        created_at_time = ?Utils.timeToNat64(time);
        fee = ?_fee; // @todo: null is supposed to work according to the token standard, but it doesn't...
        from_subaccount = ?Utils.getSubaccount(id);
        memo = null;
        to = {
          owner = receiver;
          subaccount = null; // @todo: need to support subaccount
        };
      });

      // Return an error if the transfer failed
      switch(transfer){
        case(#Err(err)) { Debug.trap("Transfer failed"); };
        case(#Ok(tx)) {};
      };

      // Remove the interac from the map
      Map.delete(_register.interacs, Map.nhash, id);
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