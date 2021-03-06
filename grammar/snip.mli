(******************************************************************************)
(*  _  __ * The Kappa Language                                                *)
(* | |/ / * Copyright 2010-2017 CNRS - Harvard Medical School - INRIA - IRIF  *)
(* | ' /  *********************************************************************)
(* | . \  * This file is distributed under the terms of the                   *)
(* |_|\_\ * GNU Lesser General Public License Version 3                       *)
(******************************************************************************)

(** Kappa pattern compiler *)

val connected_components_sum_of_ambiguous_mixture :
  compileModeOn:bool -> Contact_map.t -> Pattern.PreEnv.t ->
  ?origin:Operator.rev_dep -> LKappa.rule_mixture ->
  Pattern.PreEnv.t *
  ((Pattern.id * Pattern.cc) array *
   Instantiation.abstract Instantiation.test list list) list

val connected_components_sum_of_ambiguous_rule :
  compileModeOn:bool -> Contact_map.t -> Pattern.PreEnv.t ->
  ?origin:Operator.rev_dep -> LKappa.rule_mixture -> Raw_mixture.t ->
  (Operator.rev_dep option * (Pattern.id * Pattern.cc) array *
     (Instantiation.abstract Instantiation.event) *
       (Instantiation.abstract Primitives.Transformation.t list *
          Instantiation.abstract Primitives.Transformation.t list))
    list *   (Pattern.PreEnv.t * Operator.rev_dep option)

val patterns_of_mixture :
  (int list * (int * int) list) array array -> Signature.s ->
  Pattern.PreEnv.t -> Edges.t -> Pattern.PreEnv.t * Pattern.cc list
