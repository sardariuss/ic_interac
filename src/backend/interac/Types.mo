import Map                "mo:map/Map";

module {

  type Map<K, V> = Map.Map<K, V>;

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

};