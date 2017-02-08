(******************************************************************************)
(*  _  __ * The Kappa Language                                                *)
(* | |/ / * Copyright 2010-2017 CNRS - Harvard Medical School - INRIA - IRIF  *)
(* | ' /  *********************************************************************)
(* | . \  * This file is distributed under the terms of the                   *)
(* |_|\_\ * GNU Lesser General Public License Version 3                       *)
(******************************************************************************)

let outputDirName = ref ""
let marshalizedOutFile = ref ""
let snapshotFileName = ref "snap"
let cflowFileName = ref "cflow.dot"
let branch_and_cut_engine_profilingName = ref "compression_status.txt"
let tasks_profilingName = ref "profiling.html"
let influenceFileName = ref ""
let odeFileName  =
  begin
    List.fold_left
      (fun map (key,value) ->
         Loggers.FormatMap.add key (ref value) map)
      Loggers.FormatMap.empty
      [
        Loggers.Octave, "ode.m";
        Loggers.Matlab, "ode.m";
        Loggers.SBML, "network.xml"
      ]
  end

let get_odeFileName backend =
  try
    Loggers.FormatMap.find backend odeFileName
  with
    Not_found ->
    let output = ref "" in
    let _ = Loggers.FormatMap.add backend output odeFileName in
    output

let set_odeFileName backend name =
  let reference = get_odeFileName backend in
  reference:=name

let fluxFileName = ref ""

let path f =
  if Filename.is_implicit f && Filename.dirname f = Filename.current_dir_name
  then Filename.concat !outputDirName f
  else f

let open_out f =
  open_out (path f)

let find_available_name name facultative ext =
  let base = try Filename.chop_extension name
      with Invalid_argument _ -> name in
  if Sys.file_exists (base^"."^ext) then
    let base' = if facultative <> "" then base^"_"^facultative else base in
    if Sys.file_exists (base'^"."^ext) then
      let v = ref 0 in
      let () =
 while Sys.file_exists (base'^"~"^(string_of_int !v)^"."^ext)
 do incr v; done
      in base'^"~"^(string_of_int !v)^"."^ext
    else base'^"."^ext
  else base^"."^ext

let get_fresh_filename base_name concat_list facultative ext =
  let tmp_name =
    path (try Filename.chop_extension base_name
  with Invalid_argument _ -> base_name) in
  let base_name = String.concat "_" (tmp_name::concat_list) in
  find_available_name base_name facultative ext

let open_out_fresh_filename base_name concat_list facultative ext =
  open_out (get_fresh_filename base_name concat_list facultative ext)

let mk_dir_r d =
  let rec aux d =
    let par = Filename.dirname d in
    let () = if not (Sys.file_exists par) then aux par in
    Unix.mkdir d 0o775 in
  Unix.handle_unix_error aux d

let set name ext_opt =
  if !name <> "" then
    let fname =
      match ext_opt with
      | None -> !name
      | Some ext ->
        if (Filename.check_suffix !name ext) then !name
        else
          (!name^"."^ext) in
    name:=fname

let setOutputName () =
  set snapshotFileName (Some "dot");
  set influenceFileName (Some "dot") ;
  set fluxFileName (Some "dot") ;
  set (get_odeFileName Loggers.Octave) (Some "m") ;
  set (get_odeFileName Loggers.Matlab) (Some "m") ;
  set (get_odeFileName Loggers.SBML) (Some "xml") ;
  set marshalizedOutFile None

let setCheckFileExists ~batchmode outputFile =
  let check file =
    match file with
    | "" -> ()
    | file ->
      let file = path file in
      if not batchmode && Sys.file_exists file then
        let () =
          Format.eprintf
            "File '%s' already exists do you want to erase (y/N)?@." file in
        let answer = Tools.read_input () in
        if answer<>"y" then exit 1 in
  let () = setOutputName () in
  check !influenceFileName ;
  check !fluxFileName ;
  check !marshalizedOutFile ;
  check outputFile

let setCheckFileExistsODE ~batchmode ~mode =
    let check file =
      match file with
      | "" -> ()
      | file ->
         let file = path file in
         if not batchmode && Sys.file_exists file then
    let () =
      Format.eprintf
        "File '%s' already exists do you want to erase (y/N)?@." file in
    let answer = Tools.read_input () in
    if answer<>"y" then exit 1
    in
    let () = setOutputName () in
    check !(get_odeFileName mode)

let with_channel str f =
  if str <> ""  then
    let desc = open_out str in
    let () = f desc in
    close_out desc

let with_formatter str f =
  with_channel
    str
    (fun desc ->
     let fr = Format.formatter_of_out_channel desc in
     let () = f fr in
     Format.pp_print_flush fr ())

let set_dir s =
  let () = try
      if not (Sys.is_directory s)
      then (Format.eprintf "'%s' is not a directory@." s ; exit 1)
    with Sys_error _ -> mk_dir_r s in
  outputDirName := s

let get_dir () = !outputDirName

let set_ode ~mode f =
  set_odeFileName mode f
let get_ode ~mode =
  !(get_odeFileName mode)

let set_marshalized f = marshalizedOutFile := f
let with_marshalized f =
  match !marshalizedOutFile with
  | "" -> ()
  | file ->
     let d = open_out_bin (path file) in
     let () = f d in
     close_out d

let set_cflow s = cflowFileName := s
let get_cflow l e = get_fresh_filename !cflowFileName l "" e
let with_cflow_file l e f =
  with_formatter (get_fresh_filename !cflowFileName l "" e) f

let open_tasks_profiling () = open_out !tasks_profilingName
let open_branch_and_cut_engine_profiling () = open_out !branch_and_cut_engine_profilingName
let set_flux nme event =
  let () =
    match nme with
    | "" -> fluxFileName := "flux"^"_"^(string_of_int event)
    | _ -> fluxFileName := nme
  in
  set fluxFileName (Some "dot")

let with_flux str f =
  with_formatter (match str with "" -> !fluxFileName | _ -> str) f

let with_snapshot str event ext f =
  let str = if str="" then !snapshotFileName else str in
  let desc =
    open_out_fresh_filename
      str [] (string_of_int event) ext in
    let fr = Format.formatter_of_out_channel desc in
    let () =
      Format.fprintf fr "# Snapshot [Event: %d]@.%t@?"(*", Time: %f"*)event f in
    close_out desc
