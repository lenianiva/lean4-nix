import Std.Tactic.BVDecide

def popcount_spec (x : BitVec 32) : BitVec 32 :=
  (32 : Nat).fold (init := 0) fun i _ pop =>
    pop + ((x >>> i) &&& 1)

def popcount (x : BitVec 32) : BitVec 32 :=
  let x := x - ((x >>> 1) &&& 0x55555555)
  let x := (x &&& 0x33333333) + ((x >>> 2) &&& 0x33333333)
  let x := (x + (x >>> 4)) &&& 0x0F0F0F0F
  let x := x + (x >>> 8)
  let x := x + (x >>> 16)
  let x := x &&& 0x0000003F
  x

theorem popcount_correct : popcount = popcount_spec := by
  funext x
  simp [popcount, popcount_spec]
  bv_decide
