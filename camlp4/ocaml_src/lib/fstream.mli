(* camlp4r *)
(* Id *)

(* Module [Fstream]: functional streams *)

(* This module implement functional streams.
   To be used with syntax [pa_fstream.cmo]. The syntax is:
-     stream: [fstream [: ... :]]
-     parser: [parser [ [: ... :] -> ... | ... ]]

   Functional parsers are of type: [Fstream.t 'a -> option ('a * Fstream.t 'a)]

   They have limited backtrack, i.e if a rule fails, the next rule is tested
   with the initial stream; limited because when in case of a rule with two
   consecutive symbols [a] and [b], if [b] fails, the rule fails: there is
   no try with the next rule of [a].
*)

type 'a t;;
    (* The type of 'a functional streams *)
val from : (int -> 'a option) -> 'a t;;
    (* [Fstream.from f] returns a stream built from the function [f].
       To create a new stream element, the function [f] is called with
       the current stream count. The user function [f] must return either
       [Some <value>] for a value or [None] to specify the end of the
       stream. *)

val of_list : 'a list -> 'a t;;
    (* Return the stream holding the elements of the list in the same
       order. *)
val of_string : string -> char t;;
    (* Return the stream of the characters of the string parameter. *)
val of_channel : in_channel -> char t;;
    (* Return the stream of the characters read from the input channel. *)

val iter : ('a -> unit) -> 'a t -> unit;;
    (* [Fstream.iter f s] scans the whole stream s, applying function [f]
       in turn to each stream element encountered. *)

val next : 'a t -> ('a * 'a t) option;;
    (* Return [Some (a, s)] where [a] is the first element of the stream
       and [s] the remaining stream, or [None] if the stream is empty. *)
val empty : 'a t -> (unit * 'a t) option;;
    (* Return [Some ((), s)] if the stream is empty where [s] is itself,
       else [None] *)
val count : 'a t -> int;;
    (* Return the current count of the stream elements, i.e. the number
       of the stream elements discarded. *)
val count_unfrozen : 'a t -> int;;
    (* Return the number of unfrozen elements in the beginning of the
       stream; useful to determine the position of a parsing error (longuest
       path). *)

(*--*)

val nil : unit -> 'a t;;
type 'a data;;
val cons : 'a -> 'a t -> 'a data;;
val app : 'a t -> 'a t -> 'a data;;
val flazy : (unit -> 'a data) -> 'a t;;
