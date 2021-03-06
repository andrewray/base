open! Import

type ('a, 'b) t = ('a, 'b) Pervasives.result =
  | Ok of 'a
  | Error of 'b
[@@deriving_inline sexp, compare, hash]
let t_of_sexp : type a
                       b.(Sexplib.Sexp.t -> a) ->
  (Sexplib.Sexp.t -> b) -> Sexplib.Sexp.t -> (a,b) t
  =
  let _tp_loc = "src/result.ml.t"  in
  fun _of_a  ->
  fun _of_b  ->
    function
    | Sexplib.Sexp.List ((Sexplib.Sexp.Atom
                            ("ok"|"Ok" as _tag))::sexp_args) as _sexp ->
      (match sexp_args with
       | v0::[] -> let v0 = _of_a v0  in Ok v0
       | _ -> Sexplib.Conv_error.stag_incorrect_n_args _tp_loc _tag _sexp)
    | Sexplib.Sexp.List ((Sexplib.Sexp.Atom
                            ("error"|"Error" as _tag))::sexp_args) as _sexp ->
      (match sexp_args with
       | v0::[] -> let v0 = _of_b v0  in Error v0
       | _ -> Sexplib.Conv_error.stag_incorrect_n_args _tp_loc _tag _sexp)
    | Sexplib.Sexp.Atom ("ok"|"Ok") as sexp ->
      Sexplib.Conv_error.stag_takes_args _tp_loc sexp
    | Sexplib.Sexp.Atom ("error"|"Error") as sexp ->
      Sexplib.Conv_error.stag_takes_args _tp_loc sexp
    | Sexplib.Sexp.List ((Sexplib.Sexp.List _)::_) as sexp ->
      Sexplib.Conv_error.nested_list_invalid_sum _tp_loc sexp
    | Sexplib.Sexp.List [] as sexp ->
      Sexplib.Conv_error.empty_list_invalid_sum _tp_loc sexp
    | sexp -> Sexplib.Conv_error.unexpected_stag _tp_loc sexp

let sexp_of_t : type a
                       b.(a -> Sexplib.Sexp.t) ->
  (b -> Sexplib.Sexp.t) -> (a,b) t -> Sexplib.Sexp.t
  =
  fun _of_a  ->
  fun _of_b  ->
    function
    | Ok v0 ->
      let v0 = _of_a v0  in
      Sexplib.Sexp.List [Sexplib.Sexp.Atom "Ok"; v0]
    | Error v0 ->
      let v0 = _of_b v0  in
      Sexplib.Sexp.List [Sexplib.Sexp.Atom "Error"; v0]

let compare :
  'a 'b .
       ('a -> 'a -> int) -> ('b -> 'b -> int) -> ('a,'b) t -> ('a,'b) t -> int
  =
  fun _cmp__a  ->
  fun _cmp__b  ->
  fun a__001_  ->
  fun b__002_  ->
    if Ppx_compare_lib.phys_equal a__001_ b__002_
    then 0
    else
      (match (a__001_, b__002_) with
       | (Ok _a__003_,Ok _b__004_) -> _cmp__a _a__003_ _b__004_
       | (Ok _,_) -> (-1)
       | (_,Ok _) -> 1
       | (Error _a__005_,Error _b__006_) -> _cmp__b _a__005_ _b__006_)

let hash_fold_t : type a
                         b.(Ppx_hash_lib.Std.Hash.state -> a -> Ppx_hash_lib.Std.Hash.state) ->
  (Ppx_hash_lib.Std.Hash.state -> b -> Ppx_hash_lib.Std.Hash.state) ->
  Ppx_hash_lib.Std.Hash.state -> (a,b) t -> Ppx_hash_lib.Std.Hash.state
  =
  fun _hash_fold_a  ->
  fun _hash_fold_b  ->
  fun hsv  ->
  fun arg  ->
    match arg with
    | Ok _a0 ->
      let hsv = Ppx_hash_lib.Std.Hash.fold_int hsv 0  in
      let hsv = hsv  in _hash_fold_a hsv _a0
    | Error _a0 ->
      let hsv = Ppx_hash_lib.Std.Hash.fold_int hsv 1  in
      let hsv = hsv  in _hash_fold_b hsv _a0

[@@@end]

type ('a, 'b) _t = ('a, 'b) t

include Monad.Make2 (struct
    type ('a, 'b) t = ('a,'b) _t

    let bind x ~f = match x with
      | Error _ as x -> x
      | Ok x -> f x

    let map x ~f = match x with
      | Error _ as x -> x
      | Ok x -> Ok (f x)

    let map = `Custom map

    let return x = Ok x
  end)

let ignore = ignore_m

let fail x = Error x;;
let failf format = Printf.ksprintf fail format

(* This definition shadows the version created by the functor application above, but it
   is much more efficient. *)
let map t ~f = match t with
  | Ok x -> Ok (f x)
  | Error _ as x -> x

let map_error t ~f = match t with
  | Ok _ as x -> x
  | Error x -> Error (f x)

let is_ok = function
  | Ok _ -> true
  | Error _ -> false

let is_error = function
  | Ok _ -> false
  | Error _ -> true

let ok = function
  | Ok x -> Some x
  | Error _ -> None

let error = function
  | Ok _ -> None
  | Error x -> Some x

let of_option opt ~error =
  match opt with
  | Some x -> Ok x
  | None -> Error error

let iter v ~f = match v with
  | Ok x -> f x
  | Error _ -> ()

let iter_error v ~f = match v with
  | Ok _ -> ()
  | Error x -> f x

let ok_fst = function
  | Ok x -> `Fst x
  | Error x -> `Snd x

let ok_if_true bool ~error =
  if bool
  then Ok ()
  else Error error

let try_with f =
  try Ok (f ())
  with exn -> Error exn

let ok_unit = Ok ()

let ok_exn = function
  | Ok x -> x
  | Error exn -> raise exn

let ok_or_failwith = function
  | Ok x -> x
  | Error str -> failwith str

module Export = struct
  type ('ok, 'err) _result =
    ('ok, 'err) t =
    | Ok of 'ok
    | Error of 'err

  let is_error   = is_error
  let is_ok      = is_ok
end

let combine t1 t2 ~ok ~err =
  match t1, t2 with
  | Ok _, Error e | Error e, Ok _ -> Error e
  | Ok    ok1 , Ok    ok2  -> Ok    (ok  ok1  ok2 )
  | Error err1, Error err2 -> Error (err err1 err2)
;;


