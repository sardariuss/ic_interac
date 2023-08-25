import ICRC2  "mo:icrc2/ICRC2";

import Debug  "mo:base/Debug";
import Buffer "mo:base/Buffer";
import Iter   "mo:base/Iter";

module {

  type ApproveArgs             = ICRC2.ApproveArgs;
  type ApproveResult           = ICRC2.ApproveResult;
  type AllowanceArgs           = ICRC2.AllowanceArgs;
  type Allowance               = ICRC2.Allowance;
  type Account                 = ICRC2.Account;
  type Subaccount              = ICRC2.Subaccount;
  type Transaction             = ICRC2.Transaction;
  type Balance                 = ICRC2.Balance;
  type TransferArgs            = ICRC2.TransferArgs;
  type Mint                    = ICRC2.Mint;
  type BurnArgs                = ICRC2.BurnArgs;
  type SupportedStandard       = ICRC2.SupportedStandard;
  type InitArgs                = ICRC2.InitArgs;
  type MetaDatum               = ICRC2.MetaDatum;
  type TxIndex                 = ICRC2.TxIndex;
  type TransferResult          = ICRC2.TransferResult;
  type GetTransactionsRequest  = ICRC2.GetTransactionsRequest;
  type GetTransactionsResponse = ICRC2.GetTransactionsResponse;
  type TransferFromArgs        = ICRC2.TransferFromArgs;
  type TransferFromResult      = ICRC2.TransferFromResult;

  type Function = {
    #icrc1_name;
    #icrc1_symbol;
    #icrc1_decimals;
    #icrc1_fee;
    #icrc1_metadata;
    #icrc1_total_supply;
    #icrc1_minting_account;
    #icrc1_balance_of;
    #icrc1_supported_standards;
    #icrc1_transfer;
    #mint;
    #burn;
    #get_transactions;
    #icrc2_approve;
    #icrc2_allowance;
    #icrc2_transfer_from;
  };

  public type Args = {
    #icrc1_name                : Text;
    #icrc1_symbol              : Text;
    #icrc1_decimals            : Nat8;
    #icrc1_fee                 : Balance;
    #icrc1_metadata            : [MetaDatum];
    #icrc1_total_supply        : Balance;
    #icrc1_minting_account     : ?Account;
    #icrc1_balance_of          : Balance;
    #icrc1_supported_standards : [SupportedStandard];
    #icrc1_transfer            : TransferResult;
    #mint                      : TransferResult;
    #burn                      : TransferResult;
    #get_transactions          : GetTransactionsResponse;
    #icrc2_approve             : ApproveResult;
    #icrc2_allowance           : Allowance;
    #icrc2_transfer_from       : TransferFromResult;
  };

  func toText(function: Function) : Text {
    switch(function){
      case(#icrc1_name)                { "icrc1_name"                };
      case(#icrc1_symbol)              { "icrc1_symbol"              };
      case(#icrc1_decimals)            { "icrc1_decimals"            };
      case(#icrc1_fee)                 { "icrc1_fee"                 };
      case(#icrc1_metadata)            { "icrc1_metadata"            };
      case(#icrc1_total_supply)        { "icrc1_total_supply"        };
      case(#icrc1_minting_account)     { "icrc1_minting_account"     };
      case(#icrc1_balance_of)          { "icrc1_balance_of"          };
      case(#icrc1_supported_standards) { "icrc1_supported_standards" };
      case(#icrc1_transfer)            { "icrc1_transfer"            };
      case(#mint)                      { "mint"                      };
      case(#burn)                      { "burn"                      };
      case(#get_transactions)          { "get_transactions"          };
      case(#icrc2_approve)             { "icrc2_approve"             };
      case(#icrc2_allowance)           { "icrc2_allowance"           };
      case(#icrc2_transfer_from)       { "icrc2_transfer_from"       };
    };
  };

  func match(function: Function, args: Args) : ?Args{
    switch(function, args){
      case(#icrc1_name,                #icrc1_name(args)               ) { ?#icrc1_name(args);               };
      case(#icrc1_symbol,              #icrc1_symbol(args)             ) { ?#icrc1_symbol(args);             };
      case(#icrc1_decimals,            #icrc1_decimals(args)           ) { ?#icrc1_decimals(args);           };
      case(#icrc1_fee,                 #icrc1_fee(args)                ) { ?#icrc1_fee(args);                };
      case(#icrc1_metadata,            #icrc1_metadata(args)           ) { ?#icrc1_metadata(args);           };
      case(#icrc1_total_supply,        #icrc1_total_supply(args)       ) { ?#icrc1_total_supply(args);       };
      case(#icrc1_minting_account,     #icrc1_minting_account(args)    ) { ?#icrc1_minting_account(args);    };
      case(#icrc1_balance_of,          #icrc1_balance_of(args)         ) { ?#icrc1_balance_of(args);         };
      case(#icrc1_supported_standards, #icrc1_supported_standards(args)) { ?#icrc1_supported_standards(args);};
      case(#icrc1_transfer,            #icrc1_transfer(args)           ) { ?#icrc1_transfer(args);           };
      case(#mint,                      #mint(args)                     ) { ?#mint(args);                     };
      case(#burn,                      #burn(args)                     ) { ?#burn(args);                     };
      case(#get_transactions,          #get_transactions(args)         ) { ?#get_transactions(args);         };
      case(#icrc2_approve,             #icrc2_approve(args)            ) { ?#icrc2_approve(args);            };
      case(#icrc2_allowance,           #icrc2_allowance(args)          ) { ?#icrc2_allowance(args);          };
      case(#icrc2_transfer_from,       #icrc2_transfer_from(args)      ) { ?#icrc2_transfer_from(args);      };
      case(_,                          _                               ) { null;                             };
    };
  };

  public actor class ICRC2Mock() : async ICRC2.FullInterface  {

    let _expected_calls = Buffer.Buffer<Args>(0);

    func consumeExpectCall(function: Function) : Args {
      for (i in Iter.range(0, _expected_calls.size() - 1)){
        switch(match(function, _expected_calls.get(i))){
          case(null) {};
          case(?args) { ignore _expected_calls.remove(i); return args; };
        };
      };
      Debug.trap("Unexpected call to " # toText(function));
    };

    public func expectCall(args: Args) {
      _expected_calls.add(args);
    };

    public func hasUnconsumedCalls() : async Bool {
      return _expected_calls.size() > 0;
    };
    
    public shared query func icrc1_name() : async Text {
      switch(consumeExpectCall(#icrc1_name)){
        case(#icrc1_name(args))                { return args;                             };
        case(_)                                { Debug.trap("Mock implementation error"); };
      };
    };

    public shared query func icrc1_symbol() : async Text {
      switch(consumeExpectCall(#icrc1_symbol)){
        case(#icrc1_symbol(args))              { return args;                             };
        case(_)                                { Debug.trap("Mock implementation error"); };
      };
    };

    public shared query func icrc1_decimals() : async Nat8 {
      switch(consumeExpectCall(#icrc1_decimals)){
        case(#icrc1_decimals(args))            { return args;                             };
        case(_)                                { Debug.trap("Mock implementation error"); };
      };
    };

    public shared query func icrc1_fee() : async Balance {
      switch(consumeExpectCall(#icrc1_fee)){
        case(#icrc1_fee(args))                 { return args;                             };
        case(_)                                { Debug.trap("Mock implementation error"); };
      };
    };

    public shared query func icrc1_metadata() : async [MetaDatum] {
      switch(consumeExpectCall(#icrc1_metadata)){
        case(#icrc1_metadata(args))            { return args;                             };
        case(_)                                { Debug.trap("Mock implementation error"); };
      };
    };

    public shared query func icrc1_total_supply() : async Balance {
      switch(consumeExpectCall(#icrc1_total_supply)){
        case(#icrc1_total_supply(args))        { return args;                             };
        case(_)                                { Debug.trap("Mock implementation error"); };
      };
    };

    public shared query func icrc1_minting_account() : async ?Account {
      switch(consumeExpectCall(#icrc1_minting_account)){
        case(#icrc1_minting_account(args))     { return args;                             };
        case(_)                                { Debug.trap("Mock implementation error"); };
      };
    };

    public shared query func icrc1_balance_of(args : Account) : async Balance {
      switch(consumeExpectCall(#icrc1_balance_of)){
        case(#icrc1_balance_of(args))          { return args;                             };
        case(_)                                { Debug.trap("Mock implementation error"); };
      };
    };

    public shared query func icrc1_supported_standards() : async [SupportedStandard] {
      switch(consumeExpectCall(#icrc1_supported_standards)){
        case(#icrc1_supported_standards(args)) { return args;                             };
        case(_)                                { Debug.trap("Mock implementation error"); };
      };
    };

    public shared ({ caller }) func icrc1_transfer(args : TransferArgs) : async TransferResult {
      switch(consumeExpectCall(#icrc1_transfer)){
        case(#icrc1_transfer(args))            { return args;                             };
        case(_)                                { Debug.trap("Mock implementation error"); };
      };
    };

    public shared ({ caller }) func mint(args : Mint) : async TransferResult {
      switch(consumeExpectCall(#mint)){
        case(#mint(args))                      { return args;                             };
        case(_)                                { Debug.trap("Mock implementation error"); };
      };
    };

    public shared ({ caller }) func burn(args : BurnArgs) : async TransferResult {
      switch(consumeExpectCall(#burn)){
        case(#burn(args))                      { return args;                             };
        case(_)                                { Debug.trap("Mock implementation error"); };
      };
    };

    public shared query func get_transactions(args : GetTransactionsRequest) : async GetTransactionsResponse {
      switch(consumeExpectCall(#get_transactions)){
        case(#get_transactions(args))          { return args;                             };
        case(_)                                { Debug.trap("Mock implementation error"); };
      };
    };

    public shared ({ caller }) func icrc2_approve(args : ApproveArgs) : async ApproveResult {
      switch(consumeExpectCall(#icrc2_approve)){
        case(#icrc2_approve(args))             { return args;                             };
        case(_)                                { Debug.trap("Mock implementation error"); };
      };
    };

    public shared query func icrc2_allowance(args : AllowanceArgs) : async Allowance {
      switch(consumeExpectCall(#icrc2_allowance)){
        case(#icrc2_allowance(args))           { return args;                             };
        case(_)                                { Debug.trap("Mock implementation error"); };
      };
    };

    public shared ({ caller }) func icrc2_transfer_from(args : ICRC2.TransferFromArgs) : async TransferFromResult {
      switch(consumeExpectCall(#icrc2_transfer_from)){
        case(#icrc2_transfer_from(args))       { return args;                             };
        case(_)                                { Debug.trap("Mock implementation error"); };
      };
    };

  };

};