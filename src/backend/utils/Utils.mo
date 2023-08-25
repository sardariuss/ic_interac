import Nat8   "mo:base/Nat8";
import Nat64  "mo:base/Nat64";
import Int    "mo:base/Int";
import Blob   "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Array  "mo:base/Array";

module {

  type Time = Int;

  public let MODULE_VERSION : Nat8 = 0;

  public func getSubaccount(id: Nat) : Blob {
    let buffer = Buffer.Buffer<Nat8>(32);
    // Add the version (1 byte)
    buffer.add(MODULE_VERSION);
    // Add the id      (8 bytes)
    buffer.append(Buffer.fromArray(nat64ToBytes(Nat64.fromNat(id)))); // Traps on overflow
    // Add padding     (23 bytes)
    buffer.append(Buffer.fromArray(Array.tabulate<Nat8>(23, func i = 0)));
    // Assert that the buffer is 32 bytes
    assert(buffer.size() == 32);
    // Return the subaccount as a blob
    Blob.fromArray(Buffer.toArray(buffer));
  };

  func nat64ToBytes(x : Nat64) : [Nat8] {
    [ 
      Nat8.fromNat(Nat64.toNat((x >> 56) & (255))),
      Nat8.fromNat(Nat64.toNat((x >> 48) & (255))),
      Nat8.fromNat(Nat64.toNat((x >> 40) & (255))),
      Nat8.fromNat(Nat64.toNat((x >> 32) & (255))),
      Nat8.fromNat(Nat64.toNat((x >> 24) & (255))),
      Nat8.fromNat(Nat64.toNat((x >> 16) & (255))),
      Nat8.fromNat(Nat64.toNat((x >> 8) & (255))),
      Nat8.fromNat(Nat64.toNat((x & 255))) 
    ];
  };

  public func timeToNat64(time: Time) : Nat64 {
    Nat64.fromNat(Int.abs(time));
  };
 
};