open Angstrom
open Parsers
open Prelude
open Org

(* TODO, DOING, DONE *)
let marker = string "TODO" <|> string "DOING" <|> string "DONE"

let level = take_while1 (fun c -> c = '*')

let priority = string "[#" *> any_char <* char ']'

let seperated_tags = sep_by (char ':') (take_while1 (fun x -> x <> ':' && non_eol x))

let tags = char ':' *> seperated_tags <* char ':'

(* not priority, tags, marker *)
let title = take_while1 (function | '\r' | '\n' -> false | _ -> true)

let is_blank s =
  let n = String.length s in
  let rec aut_is_blank i =
    if i = n then true
    else
      let c = s.[i] in
      if is_space c then aut_is_blank (i + 1) else false
  in
  aut_is_blank 0

let anchor_link s =
  let map_char = function
    | ('a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '(' | ')') as c -> String.make 1 c
    | ' ' | '_' | '-' -> "_"
    | c -> Printf.sprintf "-%x-" (int_of_char c)
  in
  Prelude.explode (String.trim s) |> List.map map_char |> String.concat ""

let parse =
  let p = lift4
      (fun level marker priority title ->
         let level = String.length level in
         let title = match (parse_string Inline.parse (String.trim title)) with
           | Ok title -> title
           | Error e -> [] in
         let last_inline = List.nth title (List.length title - 1) in
         let (title, tags) = match last_inline with
           | Inline.Plain s ->
             (match parse_string tags (String.trim s) with
              | Ok tags ->
                (drop_last 1 title, remove is_blank tags)
              | _ ->
                (title, []))
           | _ -> (title, []) in
         let anchor = anchor_link (Inline.asciis title) in
         let meta = { timestamps = []; properties = []} in
         [Heading {level; marker; priority; title; tags; anchor; meta}] )
      (level <* ws <?> "Heading level")
      (optional (lex marker <?> "Heading marker"))
      (optional (lex priority <?> "Heading priority"))
      (lex title <?> "Heading title") in
  between_eols_or_spaces p

(*

let _ =
  let input = "* TODO [#A] hello :foo:bar:" in
  parse_string heading input

*)
