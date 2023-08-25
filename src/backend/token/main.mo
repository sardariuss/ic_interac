import ICRC2              "mo:icrc2/ICRC2";

import Nat8               "mo:base/Nat8";
import Principal          "mo:base/Principal";
import Debug              "mo:base/Debug";
import ExperimentalCycles "mo:base/ExperimentalCycles";

actor Token {

  let DECIMALS     : Nat = 8;
  let TOKEN_UNIT   : Nat = 10 ** DECIMALS;
  let TOKEN_SUPPLY : Nat = 1_000_000_000 * TOKEN_UNIT;
  let FEE          : Nat = 10_000;

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

  let token_args : ICRC2.TokenInitArgs = {
    name = "Token";
    symbol = "TKN";
    decimals = Nat8.fromNat(DECIMALS);
    fee = FEE;
    max_supply = TOKEN_SUPPLY;
    initial_balances = [
      ({ owner = Principal.fromText("l2dqn-dqd5a-er3f7-h472o-ainav-j3ll7-iavjt-4v6ib-c6bom-duooy-uqe"); subaccount = null;}, 500_000_000 * TOKEN_UNIT), // deployer
    ];
    min_burn_amount = FEE;
    minting_account = ?{ owner = Principal.fromText("l2dqn-dqd5a-er3f7-h472o-ainav-j3ll7-iavjt-4v6ib-c6bom-duooy-uqe"); subaccount = null; }; // master
    advanced_settings = null;
  };

  stable let token = ICRC2.init({
    token_args with minting_account = switch(token_args.minting_account){
      case(?account) { account; };
      case(null) { Debug.trap("Minting account must be specified"); };
    }
  });

  /// Functions for the 1 token standard
  public shared query func icrc1_name() : async Text {
    ICRC2.name(token);
  };

  public shared query func icrc1_symbol() : async Text {
    ICRC2.symbol(token);
  };

  public shared query func icrc1_decimals() : async Nat8 {
    ICRC2.decimals(token);
  };

  public shared query func icrc1_fee() : async Balance {
    ICRC2.fee(token);
  };

  public shared query func icrc1_metadata() : async [MetaDatum] {
    ICRC2.metadata(token);
  };

  public shared query func icrc1_total_supply() : async Balance {
    ICRC2.total_supply(token);
  };

  public shared query func icrc1_minting_account() : async ?Account {
    ?ICRC2.minting_account(token);
  };

  public shared query func icrc1_balance_of(args : Account) : async Balance {
    ICRC2.balance_of(token, args);
  };

  public shared query func icrc1_supported_standards() : async [SupportedStandard] {
    ICRC2.supported_standards(token);
  };

  public shared ({ caller }) func icrc1_transfer(args : TransferArgs) : async TransferResult {
    await* ICRC2.transfer(token, args, caller);
  };

  public shared ({ caller }) func mint(args : Mint) : async TransferResult {
    await* ICRC2.mint(token, args, caller);
  };

  public shared ({ caller }) func burn(args : BurnArgs) : async TransferResult {
    await* ICRC2.burn(token, args, caller);
  };

  // Functions from the rosetta icrc1 ledger
  public shared query func get_transactions(req : GetTransactionsRequest) : async GetTransactionsResponse {
    ICRC2.get_transactions(token, req);
  };

  // Additional functions not included in the ICRC2 standard
  public shared func get_transaction(i : TxIndex) : async ?Transaction {
    await* ICRC2.get_transaction(token, i);
  };

  // Deposit cycles into this archive canister.
  public shared func deposit_cycles() : async () {
    let amount = ExperimentalCycles.available();
    let accepted = ExperimentalCycles.accept(amount);
    assert (accepted == amount);
  };

  public query func get_cycles_balance() : async Nat {
    ExperimentalCycles.balance();
  };

  public shared ({ caller }) func icrc2_approve(args : ApproveArgs) : async ApproveResult {
    await* ICRC2.approve(token, args, caller);
  };

  public query func icrc2_allowance(args : AllowanceArgs) : async Allowance {
    ICRC2.allowance(token, args);
  };

  public shared ({ caller }) func icrc2_transfer_from(args : ICRC2.TransferFromArgs) : async ICRC2.TransferFromResult {
    await* ICRC2.transfer_from(token, args, caller);
  };

};