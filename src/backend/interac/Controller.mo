import Types     "Types";
import Utils     "../utils/Utils";

import Map       "mo:map/Map";
import Debug     "mo:base/Debug";
import Principal "mo:base/Principal";
import Array     "mo:base/Array";
import Error     "mo:base/Error";

import ICRC2     "mo:icrc2/ICRC2";

module {

  type Register       = Types.Register;
  type Interac        = Types.Interac;
  type SendResult     = Types.SendResult;
  type RedeemResult   = Types.RedeemResult;
  type ClaimResult    = Types.ClaimResult;
  type CanisterCallError = Types.CanisterCallError;
  type ICRC2Interface = ICRC2.FullInterface;
  type Balance        = ICRC2.Balance;
  type Map<K, V>      = Map.Map<K, V>;
  type Time           = Int;
  type Error          = Error.Error;

  public type Parameters = {
    transfer_fee: Balance;
    canister_id: Principal;
  };
  
  public class Controller(_register: Register, _icrc2: ICRC2Interface) {

    var _params : ?Parameters = null;

    public func init(canister_id: Principal) : async* () {
      
      // Ignore if already initialized
      if (_params != null) { return; };

      // Get the transfer fee from the token
      let transfer_fee = await _icrc2.icrc1_fee();

      // Initialize the controller
      _params := ?{ transfer_fee; canister_id; };
    };
    
    public func send(time: Time, caller: Principal, receiver: Principal, amount: Nat, question: Text, answer: Text) : async* SendResult {

      // Cannot anonymously send or receive an interac
      if (Principal.isAnonymous(caller) or Principal.isAnonymous(receiver)){
        return #err(#AnonymousNotAllowed);
      };

      // Cannot send an interac to yourself
      if (caller == receiver){
        return #err(#SelfSendNotAllowed);
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
      let transfer = try {
        await _icrc2.icrc2_transfer_from({
          spender_subaccount = null; // @todo: this is not part of the ICRC2 standard, it seems to be a mistake in the lib
          from = {
            owner = caller;
            subaccount = null; // @todo: need to support subaccount
          };
          to = {
            owner = _canister_id();
            subaccount = ?subaccount;
          };
          amount = amount + _transfer_fee(); // Need to add an additional the fee for the later transfer (claim or redeem)
          created_at_time = ?Utils.timeToNat64(time);
          fee = ?_transfer_fee(); // @todo: null is supposed to work according to the token standard, but it doesn't...
          memo = null;
        });
      } catch(e){ return #err(#ICRC2TransferFromError(toCanisterCallError(e))); };

      // Return an error if the transfer failed
      switch(transfer){
        case(#Err(err)) { return #err(#ICRC2TransferFromError(err)); };
        case(#Ok(tx)) {};
      };
      
      // Finally add the interac to the map
      // @todo: store the transaction id inside the interac, probably need to store the redeem/claim tx too,
      // but then it requires to keep the processed interac in the map
      Map.set(_register.interacs, Map.nhash, interac.id, interac);

      // Success, return the interac id
      #ok(interac.id);
    };

    public func redeem(time: Time, caller: Principal, id: Nat) : async* RedeemResult {
      
      // Get the interac from the map
      let {sender; amount} = switch(Map.get(_register.interacs, Map.nhash, id)) {
        case(null) { return #err(#InteracNotFound); };
        case(?interac) { interac; }
      };

      // Check that the caller is the sender
      if (sender != caller) {
        return #err(#RedeemNotAllowed);
      };

      // Transfer the money back to the sender
      let transfer = try {
        await _icrc2.icrc1_transfer({
          amount;
          created_at_time = ?Utils.timeToNat64(time);
          fee = ?_transfer_fee(); // @todo: null is supposed to work according to the token standard, but it doesn't...
          from_subaccount = ?Utils.getSubaccount(id);
          memo = null;
          to = {
            owner = sender;
            subaccount = null; // @todo: need to support subaccount
          };
        });
      } catch(e){ return #err(#ICRC2TransferError(toCanisterCallError(e))); };

      // Return an error if the transfer failed
      switch(transfer){
        case(#Err(err)) { return #err(#ICRC2TransferError(err)); };
        case(#Ok(tx)) {};
      };

      // Remove the interac from the map
      Map.delete(_register.interacs, Map.nhash, id);

      // Success
      #ok;
    };

    public func claim(time: Time, caller: Principal, id: Nat, proposed_answer: Text) : async* ClaimResult {

      // Get the interac from the map
      let {receiver; answer; amount} = switch(Map.get(_register.interacs, Map.nhash, id)) {
        case(null) { return #err(#InteracNotFound); };
        case(?interac) { interac; }
      };
      
      // Check that the caller is the receiver
      if (receiver != caller) {
        return #err(#ClaimNotAllowed);
      };

      // Check that the answer is correct
      if (proposed_answer != answer) {
        return #err(#WrongAnswer);
      };

      // Transfer the money to the receiver
      let transfer = try {
        await _icrc2.icrc1_transfer({
          amount;
          created_at_time = ?Utils.timeToNat64(time);
          fee = ?_transfer_fee(); // @todo: null is supposed to work according to the token standard, but it doesn't...
          from_subaccount = ?Utils.getSubaccount(id);
          memo = null;
          to = {
            owner = receiver;
            subaccount = null; // @todo: need to support subaccount
          };
        });
      } catch(e){ return #err(#ICRC2TransferError(toCanisterCallError(e))); };

      // Return an error if the transfer failed
      switch(transfer){
        case(#Err(err)) { return #err(#ICRC2TransferError(err)); };
        case(#Ok(tx)) {};
      };

      // Remove the interac from the map
      Map.delete(_register.interacs, Map.nhash, id);

      // Success
      #ok;
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

    func _transfer_fee() : Balance {
      switch(_params) {
        case(null) { Debug.trap("Controller not initialized"); };
        case(?params) { params.transfer_fee; };
      };
    };

    func _canister_id() : Principal {
      switch(_params) {
        case(null) { Debug.trap("Controller not initialized"); };
        case(?params) { params.canister_id; };
      };
    };

    func toCanisterCallError(e: Error) : CanisterCallError {
      #CanisterCallError({ code = Error.code(e); message = Error.message(e); });
    };
  };

};