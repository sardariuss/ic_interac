import ICRC2  "mo:icrc2/ICRC2";

import Map    "mo:map/Map";

import Int    "mo:base/Int";
import Result "mo:base/Result";
import Error  "mo:base/Error";

module {

  type Map<K, V>       = Map.Map<K, V>;
  type Result<Ok, Err> = Result.Result<Ok, Err>;

  public type Register = {
    interacs: Map<Nat, Interac>;  
    var idx: Nat;
  };
  
  public type Interac = {
    id       : Nat;
    sender   : Principal;
    receiver : Principal;
    amount   : Nat;
    question : Text;
    answer   : Text;
  };

  public type SendResult = Result<Nat, SendError>;
  public type RedeemResult = Result<(), RedeemError>;
  public type ClaimResult = Result<(), ClaimError>;

  public type CanisterCallError = {
    #CanisterCallError: { code: Error.ErrorCode; message: Text };
  };

  public type SendError = {
    #AnonymousNotAllowed;
    #SelfSendNotAllowed;
    #ICRC2TransferFromError: ICRC2.TransferFromError or CanisterCallError;
  };

  public type RedeemError = {
    #InteracNotFound;
    #RedeemNotAllowed;
    #ICRC2TransferError: ICRC2.TransferError or CanisterCallError;
  };

  public type ClaimError = {
    #InteracNotFound;
    #ClaimNotAllowed;
    #WrongAnswer;
    #ICRC2TransferError: ICRC2.TransferError or CanisterCallError;
  };

};