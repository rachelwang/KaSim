(**
   * ckappa_site_graph.ml
   * openkappa
   * Jérôme Feret & Ly Kim Quyen, projet Abstraction, INRIA Paris-Rocquencourt
   *
   * Creation: 2016, the 17th of November
   * Last modification: Time-stamp: <Nov 24 2016>
   *
   * Site graph
   *
   * Copyright 2010,2011,2012,2013,2014,2015,2016 Institut National de Recherche
   * en Informatique et en Automatique.
   * All rights reserved.  This file is distributed
   * under the terms of the GNU Library General Public License *)

(***************************************************************************)

let agent="agent name"
let site = "site name"
let interface = "interface"
let stateslist="state"
let prop="internal state"
let bind="binding state"
let binding_type="binding type"
let free = ""
let wildcard = "?"
let bound = "!_"
let bond_id = "bond id"
let bound_to = "bound to"
let hyp = "site graph"
let refinement = "site graph list"

let sanity of_json to_json elt =
  let output = to_json elt in
  let _ = of_json output in
  output

(***************************************************************************)

let pair_to_json (p: string * string): Yojson.Basic.json =
  JsonUtil.of_pair ~lab1:agent ~lab2:site
    (fun a ->  JsonUtil.of_string a)
    (fun b ->  JsonUtil.of_string b)
    p

let pair_of_json (json:Yojson.Basic.json) : string * string  =
  let (agent_name, site_name) =
    JsonUtil.to_pair ~lab1:agent ~lab2:site
      (fun json_a -> JsonUtil.to_string json_a)
      (fun json_b -> JsonUtil.to_string json_b)
      json
  in
  (agent_name,site_name)

(***************************************************************************)
(*site graph to json*)
(***************************************************************************)

let interface_to_json site_map : Yojson.Basic.json =
  Wrapped_modules.LoggedStringMap.to_json
    ~lab_key:site ~lab_value:stateslist
    JsonUtil.of_string
    (fun (internal_opt, binding_opt) ->
       JsonUtil.of_pair ~lab1:prop ~lab2:bind
         (fun internal_opt ->
            JsonUtil.of_option
              (fun internal_state ->
                JsonUtil.of_string internal_state
              ) internal_opt
         )
         (fun binding_opt ->
            match binding_opt with
            | None -> `Null
            | Some Ckappa_backend.Ckappa_backend.Free ->
              `Assoc [free, `Null]
            | Some Ckappa_backend.Ckappa_backend.Wildcard ->
              `Assoc [wildcard, `Null]
            | Some Ckappa_backend.Ckappa_backend.Bound_to_unknown ->
              `Assoc [bound_to, `Null]
            | Some (Ckappa_backend.Ckappa_backend.Bound_to i) ->
              `Assoc [bond_id, JsonUtil.of_int
                        (Ckappa_backend.Ckappa_backend.int_of_bond_index i)]
            | Some (Ckappa_backend.Ckappa_backend.Binding_type
                      (agent_name, site_name)) ->
              `Assoc [binding_type, pair_to_json (agent_name, site_name)]
         )
         (internal_opt, binding_opt)
    )
    site_map

(***************************************************************************)

let agent_to_json =
  JsonUtil.of_pair ~lab1:agent ~lab2:interface
    JsonUtil.of_string
    interface_to_json

let string_version_to_json string_version =
  let list =
    List.rev
      (Ckappa_sig.Agent_id_map_and_set.Map.fold
         (fun _ (agent_string, site_map) current_list ->
            let site_graph =
              (agent_string, site_map) :: current_list
            in
            site_graph
         ) string_version [])
  in
  JsonUtil.of_list agent_to_json list

(***************************************************************************)

let to_json graph =
  let string_version = Ckappa_backend.Ckappa_backend.get_string_version graph
  in
  string_version_to_json string_version

let site_graph_to_json = JsonUtil.of_list agent_to_json

let site_graphs_list_to_json = JsonUtil.of_list site_graph_to_json

let site_graph_lemma_to_json lemma =
  let get_hyp = Remanent_state.get_hyp lemma in
  let get_refinement = Remanent_state.get_refinement lemma in
  `Assoc [
    hyp, site_graph_to_json get_hyp;
    refinement, site_graphs_list_to_json get_refinement]

let lemmas_list_to_json constraints_list =
  JsonUtil.of_assoc (fun (abstract_domain,lemma_list) ->
      let json =
        JsonUtil.of_list (fun lemma ->
            site_graph_lemma_to_json lemma
          ) lemma_list
      in
      abstract_domain, json
    ) constraints_list

(*******************************************************************)
(*json -> contrainst_list/internal_constraints_list*)
(*******************************************************************)

(* JF:  This is quite suspicious *)
(* You should test and check that if you start with an elt, you apply to_json,
   then of_json, you get back the initial elt without any warning*)

let binding_opt_of_json
    ?error_msg:(error_msg = "Not an option binding of json") =
  function
  | `Assoc [s, json] ->
    if s = free then Ckappa_backend.Ckappa_backend.Free
    else if s = wildcard then Ckappa_backend.Ckappa_backend.Wildcard
    else if s = bound then Ckappa_backend.Ckappa_backend.Bound_to_unknown
    else if s = bound_to
    then
      let int = JsonUtil.to_int
          ~error_msg:(JsonUtil.build_msg "bound to") json
      in
      let bond_index = Ckappa_backend.Ckappa_backend.bond_index_of_int int in
      Ckappa_backend.Ckappa_backend.Bound_to bond_index
    else if s = bind
    then
      let agent_name =
        (fun json ->
           JsonUtil.to_string ~error_msg:(JsonUtil.build_msg agent)
             json)
      in
      let site_name =
        (fun json ->
           JsonUtil.to_string ~error_msg:(JsonUtil.build_msg site) json)
      in
      let (agent_name, site_name) =
        (JsonUtil.to_pair
           ~lab1:agent ~lab2:site ~error_msg:""
           (fun json -> agent_name json)
           (fun json -> site_name json)
           json)
      in
      Ckappa_backend.Ckappa_backend.Binding_type (agent_name, site_name)
    else
      assert false
  | x ->  raise (Yojson.Basic.Util.Type_error (error_msg, x))

let interface_of_json json =
  Wrapped_modules.LoggedStringMap.of_json
    ~lab_key:site ~lab_value:stateslist ~error_msg:"site_map"
    (fun json -> (*elt:site_string*)
       JsonUtil.to_string ~error_msg:(JsonUtil.build_msg site) json
    )
    (fun json -> (*internal_opt, binding_opt*)
       JsonUtil.to_pair ~lab1:prop ~lab2:bind ~error_msg:""
         (fun json ->
            JsonUtil.to_option
              (fun json ->
                 JsonUtil.to_string ~error_msg:(JsonUtil.build_msg prop)
                   json)
              json)
         (fun json ->
            JsonUtil.to_option
              (fun json ->
                 binding_opt_of_json json)
              json)
         json)
    json

let string_version_of_json json =
  JsonUtil.to_list ~error_msg:"string_version" (fun json ->
      JsonUtil.to_pair
        (fun json ->
           JsonUtil.to_string
             ~error_msg:(JsonUtil.build_msg agent) json
        )
        (fun json ->
           interface_of_json json
        )
        json
    ) json

let site_graph_list_of_json json =
  JsonUtil.to_list ~error_msg:"list of site graphs"
    (fun json -> string_version_of_json json)
    json

  (*json -> lemma *)
  let site_graph_lemma_of_json json =
  {
    Remanent_state.hyp = string_version_of_json json;
    Remanent_state.refinement = site_graph_list_of_json json;
  }

  let lemmas_list_of_json json =
    JsonUtil.to_list (* No, pattern_to_json uses association list (not list),
                        you should use to_assoc instead and provide an error message ~error_msg to help debugging *)
      (fun json ->
         JsonUtil.to_pair
           (fun json ->
              JsonUtil.to_string
                ~error_msg:(JsonUtil.build_msg agent) json)
           (fun json ->(*site graph lemma list*)
              JsonUtil.to_list (fun json ->
               site_graph_lemma_of_json json
             ) json
        ) json) json

(*TODO: CHEck*)
(*let internal_opt json =
  let internal_opt =
    JsonUtil.to_option
      (fun json ->
         match json with
         | `Assoc [prop,json] ->
           let s = JsonUtil.to_string json in
           Some s
         | _ -> None
      )
      json
  in
  internal_opt

let binding_of_json json =
  let binding_option =
    JsonUtil.to_option
      (fun json ->
         match json with
         | `Null -> None
         | `Assoc [free, `Null] -> Some Ckappa_backend.Ckappa_backend.Free
         | `Assoc [wildcard, `Null] ->
           Some Ckappa_backend.Ckappa_backend.Wildcard
         | `Assoc [bound_to, `Null] ->
           Some Ckappa_backend.Ckappa_backend.Bound_to_unknown
         | `Assoc [bond_id, j] ->
           let i =
             JsonUtil.to_int j
           in
           let bond_index = Ckappa_backend.Ckappa_backend.bond_index_of_int i in
           Some (Ckappa_backend.Ckappa_backend.Bound_to bond_index)
         | `Assoc [binding_type, j] ->
           let (agent_name, site_name) =
             pair_of_json j
           in
           Some (Ckappa_backend.Ckappa_backend.Binding_type
                   (agent_name, site_name))
      )
      json
  in
  binding_option

let interface_of_json json =
  Wrapped_modules.LoggedStringMap.of_json
    ~lab_key:site ~lab_value:stateslist
    (fun json ->
       JsonUtil.to_string json
    )
    (fun json ->
       JsonUtil.to_pair ~lab1:prop ~lab2:bind
         (fun json ->
            internal_opt json
         )
         (fun json ->
            binding_of_json json
         )
         json
    ) json

let agent_of_json =
  JsonUtil.to_pair ~lab1:agent ~lab2:interface
    JsonUtil.to_string
    interface_of_json

let string_version_of_json json =
  JsonUtil.to_list agent_of_json json


let of_json json =
  string_version_of_json json

let site_graph_of_json = JsonUtil.to_list agent_of_json

let site_graphs_list_of_json = JsonUtil.to_list site_graph_of_json

let site_graph_lemma_of_json json =
  {
    Remanent_state.hyp = site_graph_of_json json;
    Remanent_state.refinement = site_graphs_list_of_json json
  }

let pattern_of_json json =
  JsonUtil.to_assoc
    (fun (s, json) ->
       let l =
         JsonUtil.to_list
           (fun json ->
              site_graph_lemma_of_json json
           ) json
       in
       l
    )
    json*)

(*******************************************************************)
(*TODO*)



let lemmas_list_to_json = sanity lemmas_list_of_json lemmas_list_to_json

(*******************************************************************)

let print_internal_pattern_aux ?logger parameters error kappa_handler
    internal_constraints_list =
  let logger =
    match
      logger
    with
    | None -> Remanent_parameters.get_logger parameters
    | Some a -> a
  in
  let (domain_name, lemma_list) = internal_constraints_list in
  let () =
    Loggers.fprintf logger
      "------------------------------------------------------------\n";
    Loggers.fprintf logger "* Export %s to JSon (internal constraints_list):\n"
      domain_name;
    Loggers.fprintf logger
      "------------------------------------------------------------\n";
  in
  List.fold_left (fun (error, bool) lemma ->
      let hyp = Remanent_state.get_hyp lemma in
      let refinement = Remanent_state.get_refinement lemma in
      let error =
        Ckappa_backend.Ckappa_backend.print
          logger parameters error
          kappa_handler
          hyp
      in
      let () = Loggers.fprintf logger "=> [" in
      let error, b =
        match refinement with
        | [] -> error, false
        | [hyp] ->
          Ckappa_backend.Ckappa_backend.print logger parameters error
            kappa_handler
            hyp, false
        | _::_ as l ->
          List.fold_left (fun (error, bool) hyp ->
              let () =
                Loggers.print_newline
                  (Remanent_parameters.get_logger parameters)
              in
              let () =
                Loggers.fprintf
                  (Remanent_parameters.get_logger parameters)
                  (if bool  then "\t\tv " else "\t\t  ")
              in
              let error =
                Ckappa_backend.Ckappa_backend.print logger parameters error
                  kappa_handler
                  hyp
              in
              error, true
            ) (error, false) (List.rev l)
      in
      let () = Loggers.fprintf logger "]" in
      let () = Loggers.print_newline logger in
      error, b
    ) (error, false) lemma_list

(*print the information as the output of non relational properties*)
let print_internal_pattern ?logger parameters error kappa_handler
    list =
  let logger' =
    match
      logger
    with
    | None -> Remanent_parameters.get_logger parameters
    | Some a -> a
  in
  let error =
    List.fold_left (fun error pattern ->
        let error, _ =
          print_internal_pattern_aux
            ?logger parameters error
            kappa_handler
            pattern
        in
        let () = Loggers.print_newline logger' in
        error
      ) error list
  in
  error

(***************************************************************************)

let print_for_list logger parameter error kappa_handler t =
  let _bool =
    List.fold_left (fun bool (agent_string, site_map) ->
        let _ =
          Ckappa_backend.Ckappa_backend.print_aux logger parameter error
            kappa_handler
            agent_string site_map bool
        in
        let () = Loggers.fprintf logger ")" in
        true
      ) false t
  in
  let () = Loggers.fprintf logger " " in
  error

let print_pattern_aux ?logger
    parameters error kappa_handler constraints_list
  =
  let logger =
    match
      logger
    with
    | None -> Remanent_parameters.get_logger parameters
    | Some a -> a
  in
  let (domain_name, lemma_list) = constraints_list in
  let () =
    Loggers.fprintf logger
      "------------------------------------------------------------\n";
    Loggers.fprintf logger "* Export %s to JSon (constraints_list):\n" domain_name;
    Loggers.fprintf logger
      "------------------------------------------------------------\n";
  in
  List.fold_left (fun (error, bool) lemma ->
      let hyp = Remanent_state.get_hyp lemma in
      let refinement = Remanent_state.get_refinement lemma in
      let error =
        print_for_list logger parameters error
          kappa_handler
          hyp
      in
      let () = Loggers.fprintf logger " => [" in
      (*refinement*)
      let error, b =(*TODO*)
        (*match lemma.refinement with
          | [] -> error, false
          | [hyp] ->
          print_for_list logger parameters error
          kappa_handler
            hyp, false
          | _:: _ as l ->*)
        List.fold_left (fun (error, bool) hyp ->
            let () =
              Loggers.print_newline
                (Remanent_parameters.get_logger parameters)
            in
            let () =
              Loggers.fprintf
                (Remanent_parameters.get_logger parameters)
                (if bool  then "\t\tv " else "\t\t  ")
            in
            let error =
              print_for_list logger parameters error kappa_handler hyp
            in
            error, true
          ) (error, false) (List.rev refinement)
      in
      let () = Loggers.fprintf logger "]" in
      let () = Loggers.print_newline logger in
      error, b
    ) (error, false) lemma_list

let print_pattern ?logger parameters error kappa_handler list =
  let logger' =
    match
      logger
    with
    | None -> Remanent_parameters.get_logger parameters
    | Some a -> a
  in
  let error =
    List.fold_left (fun error pattern ->
        let error, _ =
          print_pattern_aux ?logger parameters error kappa_handler pattern
        in
        let () = Loggers.print_newline logger' in
        error
      ) error list
  in
  error

(*******************************************************************)

let site_graph_to_list error string_version =
  let error, current_list =
    Ckappa_sig.Agent_id_map_and_set.Map.fold
      (fun _ (agent_string, site_map) (error, current_list) ->
         (*-----------------------------------------*)
         let site_graph =
           (agent_string, site_map) :: current_list
         in
         error, site_graph
      ) string_version (error, [])
  in
  error, List.rev current_list

let site_graph_list_to_list error list =
  List.fold_left (fun (error, current_list) t ->
      let string_version = Ckappa_backend.Ckappa_backend.get_string_version t in
      let error, site_graph = site_graph_to_list error string_version in
      error, site_graph :: current_list
    ) (error, []) list

let pair_list_to_list parameters error kappa_handler pattern
    agent_id1 site_type1' agent_id2 site_type2'
    pair_list =
  List.fold_left (fun (error, current_list) l ->
      match l with
      | [siteone, state1; sitetwo, state2] when
          siteone == Ckappa_sig.fst_site
          && sitetwo == Ckappa_sig.snd_site ->
        let error, pattern =
          Ckappa_backend.Ckappa_backend.add_state
            parameters error kappa_handler
            agent_id1
            site_type1'
            state1
            pattern
        in
        let error, pattern =
          Ckappa_backend.Ckappa_backend.add_state
            parameters error kappa_handler
            agent_id2
            site_type2'
            state2
            pattern
        in
        let string_version =
          Ckappa_backend.Ckappa_backend.get_string_version
            pattern
        in
        let error, site_graph = site_graph_to_list error string_version in
        error, site_graph :: current_list
      | _ -> Exception.warn parameters error __POS__ Exit []
    ) (error, []) pair_list

let internal_pair_list_to_list parameters error kappa_handler pattern
    agent_id1 site_type1' agent_id2 site_type2' pair_list =
  List.fold_left (fun (error, current_list) l ->
      match l with
      | [siteone, state1; sitetwo, state2] when
          siteone == Ckappa_sig.fst_site
          && sitetwo == Ckappa_sig.snd_site ->
        let error, pattern =
          Ckappa_backend.Ckappa_backend.add_state
            parameters error kappa_handler
            agent_id1
            site_type1'
            state1
            pattern
        in
        let error, pattern =
          Ckappa_backend.Ckappa_backend.add_state
            parameters error kappa_handler
            agent_id2
            site_type2'
            state2
            pattern
        in
        error, pattern :: current_list
      | _ -> Exception.warn parameters error __POS__ Exit []
    ) (error, []) pair_list

(******************************************************************)
