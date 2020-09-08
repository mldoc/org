open Angstrom
open Type
open Prelude

let with_pos_meta p =
  lift3 (fun start_pos t end_pos ->
      (t, {start_pos; end_pos}))
    pos p pos

let with_end_pos_meta p =
  lift2 (fun t end_pos ->
      (t, end_pos))
    p pos
