(* camlp4r *)
(***********************************************************************)
(*                                                                     *)
(*                             Camlp4                                  *)
(*                                                                     *)
(*        Daniel de Rauglaudre, projet Cristal, INRIA Rocquencourt     *)
(*                                                                     *)
(*  Copyright 1998 Institut National de Recherche en Informatique et   *)
(*  Automatique.  Distributed only by permission.                      *)
(*                                                                     *)
(***********************************************************************)

(* Id *)

(* Module [Grammar]: extensible grammars *)

(* This module implements the Camlp4 extensible grammars system.
   Grammars entries can be extended using the [EXTEND] statement,
   added by loading the Camlp4 [pa_extend.cmo] file. *)

type g;;
    (* The type for grammars, holding entries. *)
val create : Token.lexer -> g;;
    (* Create a new grammar, without keywords, using the lexer given
       as parameter. *)
val tokens : g -> string -> (string * int) list;;
    (* Given a grammar and a token pattern constructor, returns the list of
       the corresponding values currently used in all entries of this grammar.
       The integer is the number of times this pattern value is used.

       Examples:
-      If the associated lexer uses ("", xxx) to represent a keyword
       (what is represented by then simple string xxx in an [EXTEND]
       statement rule), the call [Grammar.token g ""] returns the keywords
       list.
-      The call [Grammar.token g "IDENT"] returns the list of all usages
       of the pattern "IDENT" in the [EXTEND] statements. *)

module Entry :
  sig
    type 'a e;;
    val create : g -> string -> 'a e;;
    val parse : 'a e -> char Stream.t -> 'a;;
    val parse_token : 'a e -> Token.t Stream.t -> 'a;;
    val name : 'a e -> string;;
    val of_parser : g -> string -> (Token.t Stream.t -> 'a) -> 'a e;;
    val print : 'a e -> unit;;
    val find : 'a e -> string -> Obj.t e;;
    external obj : 'a e -> Gramext.g_entry = "%identity";;
  end
;;
    (* Module to handle entries.
-      * [Entry.e] is the type for entries returning values of type ['a].
-      * [Entry.create g n] creates a new entry named [n] in the grammar [g].
-      * [Entry.parse e] returns the stream parser of the entry [e].
-      * [Entry.parse_token e] returns the token parser of the entry [e].
-      * [Entry.name e] returns the name of the entry [e].
-      * [Entry.of_parser g n p] makes an entry from a token stream parser.
-      * [Entry.print e] displays the entry [e] using [Format].
-      * [Entry.find e s] finds the entry named [s] in [e]'s rules.
-      * [Entry.obj e] converts an entry into a [Gramext.g_entry] allowing
-        to see what it holds ([Gramext] is visible, but not documented). *)

val of_entry : 'a Entry.e -> g;;
    (* Return the grammar associated with an entry. *)

val error_verbose : bool ref;;
    (* Flag for displaying more information in case of parsing error;
       default = [False] *)

val warning_verbose : bool ref;;
    (* Flag for displaying warnings while extension; default = [True] *)

val strict_parsing : bool ref;;
    (* Flag to apply strict parsing, without trying to recover errors;
       default = [False] *)

(*** Clearing grammars and entries *)

module Unsafe :
  sig
    val reinit_gram : g -> Token.lexer -> unit;;
    val clear_entry : 'a Entry.e -> unit;;
  end
;;
    (* Module for clearing grammars and entries. To be manipulated with
       care, because: 1) reinitializing a grammar destroys all tokens
       and there may have problems with the associated lexer if it has
       a notion of keywords; 2) clearing an entry does not destroy the
       tokens used only by itself.
-      * [Unsafe.reinit_gram g lex] removes the tokens of the grammar
-        and sets [lex] as a new lexer for [g]. Warning: the lexer
-        itself is not reinitialized.
-      * [Unsafe.clear_entry e] removes all rules of the entry [e]. *)

(*** Functions called by statements EXTEND and DELETE RULE *)

(* These functions are not to be used directly. The statements [EXTEND]
   and [DELETE_RULE] use these functions generating type constraints which
   ensure the typing consistency. *)

val extend :
  (Gramext.g_entry * Gramext.position option *
     (string option * Gramext.g_assoc option *
        (Gramext.g_symbol list * Gramext.g_action) list)
       list)
    list ->
    unit;;

val delete_rule : 'a Entry.e -> Gramext.g_symbol list -> unit;;

(*** Functorial interface *)

    (* Alternative for grammars use. Grammars are not yet Ocaml values:
       there is no type for them. Modules generated preserve the
       rule "an entry cannot call an entry of another grammar" by
       normal Ocaml typing. *)

module type LexerType = sig val lexer : Token.lexer;; end;;
    (* The input signature for the functor [Grammar.Make].
       [lexer] is the lexer used. *)

module type S =
  sig
    type parsable;;
    val parsable : char Stream.t -> parsable;;
    val tokens : string -> (string * int) list;;
    module Entry :
      sig
        type 'a e;;
        val create : string -> 'a e;;
        val parse : 'a e -> parsable -> 'a;;
        val parse_token : 'a e -> Token.t Stream.t -> 'a;;
        val name : 'a e -> string;;
        val of_parser : string -> (Token.t Stream.t -> 'a) -> 'a e;;
        val print : 'a e -> unit;;
        external obj : 'a e -> Gramext.g_entry = "%identity";;
      end
    ;;
    module Unsafe :
      sig
        val reinit_gram : Token.lexer -> unit;;
        val clear_entry : 'a Entry.e -> unit;;
      end
    ;;
    val extend :
      'a Entry.e -> Gramext.position option ->
        (string option * Gramext.g_assoc option *
           (Gramext.g_symbol list * Gramext.g_action) list)
          list ->
        unit;;
    val delete_rule : 'a Entry.e -> Gramext.g_symbol list -> unit;;
  end
;;
    (* Signature type of the functor [Grammar.Make]. The types and
       functions are almost the same than in generic interface, but:
-      * Grammars are not values. Functions holding a grammar as parameter
-        do not have this parameter yet.
-      * The type [parsable] is used in function [parse] instead of
-        the char stream, avoiding the possible loss of tokens. *)

module Make : functor (L : LexerType) -> S;;

(*--*)

(*** For system use *)

val loc_of_token_interval : int -> int -> int * int;;
