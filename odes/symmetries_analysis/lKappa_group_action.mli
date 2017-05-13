(**
   * LKappa_group_action.ml
   * openkappa
   * Jérôme Feret & Ly Kim Quyen, projet Antique, INRIA Paris-Rocquencourt
   *
   * Creation: 2016, the 5th of December
   * Last modification: Time-stamp: <May 13 2017>
   *
   * Abstract domain to record relations between pair of sites in connected agents.
   *
   * Copyright 2010,2011,2012,2013,2014,2015,2016 Institut National de Recherche
   * en Informatique et en Automatique.
   * All rights reserved.  This file is distributed
   * under the terms of the GNU Library General Public License *)

(** check_orbit_internal_state_permutation ~agent_type ~site1 ~site2 rule
    ~correct rates cache ~counter to_be_checked
    will visit the orbit of rule when swapping the internal states of site1 and site2 in agents of type agent_type;
    rates contains the rate of each rule (stored according to their hash)
    to be divided by the respecive integer in correct.
    counter is an array of 0 (after the call, the array is reset to 0.
    to_be_checked is an array of boolean: false means that there is no rule corresponding to this hash, or that this rule is already in an orbit;
     true, means that there is a rule corresponding to this hash, and it does not belong to a visited orbit *)

val check_orbit_internal_state_permutation:
  ?parameters:Remanent_parameters_sig.parameters ->
  ?sigs:Signature.s ->
  agent_type:int ->
  site1:int ->
  site2:int ->
  LKappa.rule ->
  correct:(int array) -> (*what i have to divide to get gamma *)
  ('a, 'b) Alg_expr.e Locality.annot Rule_modes.RuleModeMap.t array ->
  LKappa_auto.cache ->
  counter:(int array) -> (*counter the number of array of orbit*)
  bool array -> (LKappa_auto.cache * int array * bool array) * bool

(**
   check_orbit_binding_state_permutation ~agent_type ~site1 ~site2 rule
    ~correct rates cache ~counter to_be_checked
    will visit the orbit of rule when swapping the binding states of site1 and site2 in agents of type agent_type;
    rates contains the rate of each rule (stored according to their hash)
    to be divided by the respecive integer in correct.
    counter is an array of 0 (after the call, the array is reset to 0.
    to_be_checked is an array of boolean: false means that there is no rule corresponding to this hash, or that this rule is already in an orbit;
     true, means that there is a rule corresponding to this hash, and it does not belong to a visited orbit *)
val check_orbit_binding_state_permutation:
  ?parameters:Remanent_parameters_sig.parameters ->
  ?sigs:Signature.s ->
  agent_type:int ->
  site1:int ->
  site2:int ->
  LKappa.rule ->
  correct:(int array) ->
  ('a, 'b) Alg_expr.e Locality.annot Rule_modes.RuleModeMap.t array ->
  LKappa_auto.cache ->
  counter:(int array) ->
  bool array -> (LKappa_auto.cache * int array * bool array) * bool

(**
   check_orbit_full_permutation ~agent_type ~site1 ~site2 rule
    ~correct rates cache ~counter to_be_checked
    will visit the orbit of rule when swapping both the binding and the internal states of site1 and site2 in agents of type agent_type;
    rates contains the rate of each rule (stored according to their hash)
    to be divided by the respecive integer in correct.
    counter is an array of 0 (after the call, the array is reset to 0.
    to_be_checked is an array of boolean: false means that there is no rule corresponding to this hash, or that this rule is already in an orbit;
     true, means that there is a rule corresponding to this hash, and it does not belong to a visited orbit *)

val check_orbit_full_permutation:
  ?parameters:Remanent_parameters_sig.parameters ->
  ?sigs:Signature.s ->
  agent_type:int ->
  site1:int ->
  site2:int ->
  LKappa.rule ->
  correct:(int array) ->
  ('a, 'b) Alg_expr.e Locality.annot Rule_modes.RuleModeMap.t array ->
  LKappa_auto.cache ->
  counter:(int array) ->
  bool array -> (LKappa_auto.cache * int array * bool array) * bool

val is_invariant_internal_states_permutation:
  ?parameters:Remanent_parameters_sig.parameters ->
  ?sigs:Signature.s ->
  agent_type:int ->
  site1:int ->
  site2:int ->
  LKappa.rule ->
  LKappa_auto.cache ->
  LKappa_auto.cache * bool

val is_invariant_binding_states_permutation:
  ?parameters:Remanent_parameters_sig.parameters ->
  ?sigs:Signature.s ->
  agent_type:int ->
  site1:int ->
  site2:int ->
  LKappa.rule ->
  LKappa_auto.cache ->
  LKappa_auto.cache * bool

val is_invariant_full_states_permutation:
  ?parameters:Remanent_parameters_sig.parameters ->
  ?sigs:Signature.s ->
  agent_type:int ->
  site1:int ->
  site2:int ->
  LKappa.rule ->
  LKappa_auto.cache ->
  LKappa_auto.cache * bool

val equiv_class:
  ?parameters:Remanent_parameters_sig.parameters ->
  ?sigs:Signature.s ->
  LKappa_auto.cache ->
  bool Mods.DynArray.t ->
  LKappa.rule ->
  partitions_internal_states:(int -> int list list) ->
  partitions_binding_states:(int -> int list list) ->
  partitions_full_states:(int -> int list list) ->
  convention:Remanent_parameters_sig.rate_convention ->
  LKappa_auto.cache * bool Mods.DynArray.t *
  (LKappa.rule * int) list
