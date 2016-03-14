(**
    * ode_fragmentation.ml
    * openkappa
    * Jérôme Feret & Ly Kim Quyen, projet Abstraction, INRIA Paris-Rocquencourt
    * 
    * Creation: 2015, the 9th of Apirl
    * Last modification: 
    * * 
    * ODE fragmentation
    * 
    *  
    * Copyright 2010,2011 Institut National de Recherche en Informatique et   
    * en Automatique.  All rights reserved.  This file is distributed     
    *  under the terms of the GNU Library General Public License *)

let warn parameter mh message exn default =
  Exception.warn parameter mh (Some "ODE fragmentation type") message exn
                 (fun () -> default)

let trace = false

(************************************************************************************)
(*TYPE*)

(*module AgentMap = Quick_Nearly_inf_Imperatif*)

module Internal_flow_map =
  SetMap.Make (
    struct 
      type t = Ckappa_sig.c_agent_name
      let compare = compare
    end)

module External_flow_map =
  SetMap.Make (
    struct
      type t = Ckappa_sig.c_agent_name * Ckappa_sig.c_agent_name
      let compare = compare
    end)

type ode_frag =
    {
      store_sites_modified_set:
      Ckappa_sig.Site_map_and_set.Set.t Ckappa_sig.Agent_type_quick_nearly_inf_Imperatif.t;
      store_sites_bond_pair_set: 
        Ckappa_sig.Site_map_and_set.Set.t
        Ckappa_sig.Agent_type_quick_nearly_inf_Imperatif.t * 
        Ckappa_sig.Site_map_and_set.Set.t 
        Ckappa_sig.Agent_type_quick_nearly_inf_Imperatif.t;
      store_sites_bond_pair_set_external  : 
        Ckappa_sig.Site_map_and_set.Set.t 
        Ckappa_sig.Agent_type_quick_nearly_inf_Imperatif.t * 
        Ckappa_sig.Site_map_and_set.Set.t
        Ckappa_sig.Agent_type_quick_nearly_inf_Imperatif.t;
      store_sites_lhs                     : Ckappa_sig.c_site_name list
        Ckappa_sig.Agent_type_quick_nearly_inf_Imperatif.t;
      store_sites_anchor_set              : 
        Ckappa_sig.Site_map_and_set.Set.t
        Ckappa_sig.Agent_type_quick_nearly_inf_Imperatif.t *
        Ckappa_sig.Site_map_and_set.Set.t 
        Ckappa_sig.Agent_type_quick_nearly_inf_Imperatif.t;
      store_internal_flow                 : 
        (Ckappa_sig.c_site_name list * Ckappa_sig.Site_map_and_set.Set.t) Internal_flow_map.Map.t *
        (Ckappa_sig.c_site_name list * Ckappa_sig.Site_map_and_set.Set.t) Internal_flow_map.Map.t;
      store_external_flow                 :
        (Ckappa_sig.Site_map_and_set.Set.t * Ckappa_sig.Site_map_and_set.Set.t * Ckappa_sig.Site_map_and_set.Set.t)
        External_flow_map.Map.t;
    }
