(******************************************************************************)
(*  _  __ * The Kappa Language                                                *)
(* | |/ / * Copyright 2010-2017 CNRS - Harvard Medical School - INRIA - IRIF  *)
(* | ' /  *********************************************************************)
(* | . \  * This file is distributed under the terms of the                   *)
(* |_|\_\ * GNU Lesser General Public License Version 3                       *)
(******************************************************************************)

module Html = Tyxml_js.Html5
open Lwt.Infix

let div_axis_select_id  = "plot-axis-select"
let display_id = "plot-display"
let export_id = "plot-export"

type offset = { offset_current : int ;
                offset_max : int ; }
let offset , set_offset = React.S.create (None : offset option)

let default_point = 1000
let point , set_points = React.S.create default_point

let has_plot (state : Api_types_j.simulation_info option) : bool =
  match state with
  | None -> false
  | Some state ->
    state.Api_types_j.simulation_info_output.Api_types_j.simulation_output_plot > 0
let plot_time
    (state : Api_types_j.simulation_info option) : float option =
  match state with
  | None -> None
  | Some state ->
    Some state.
           Api_types_j.
           simulation_info_progress.
           Api_types_j.
           simulation_progress_time

let serialize_json : (unit -> string) ref = ref (fun _ -> "null")
let serialize_csv : (unit -> string) ref = ref (fun _ -> "")

let configuration () : Widget_export.configuration =
  { Widget_export.id = export_id
  ; Widget_export.handlers =
      [ Widget_export.export_svg ~svg_div_id:display_id ()
      ; Widget_export.export_png ~svg_div_id:display_id ()
      ; Widget_export.export_json
          ~serialize_json:!serialize_json
      ; { Widget_export.suffix = "csv"
        ; Widget_export.label = "csv"
        ; Widget_export.export =
            fun (filename : string) ->
              let data = !serialize_csv ()
              in
              Common.saveFile
                ~data:data
                ~mime:"text/csv"
                ~filename:filename
        }
      ];
    show =
      React.S.map
        (fun model -> has_plot (State_simulation.model_simulation_info model))
        State_simulation.model
  }

let plot_points_input_id = "plot_points_input"
let plot_points_input =
  Html.input ~a:[ Html.a_id plot_points_input_id ;
                  Html.a_input_type `Number;
                  Html.a_class ["form-control"];
                  Html.a_size 5;
                ] ()

let plot_offset_input_id = "plot_offset_input"
let plot_offset_input =
  Html.input ~a:[ Tyxml_js.R.Html.a_class
                     (React.S.bind
                       offset
                       (function
                         | None -> React.S.const [ "hide" ]
                         | Some _ -> React.S.const [])
                     );
                  Tyxml_js.R.Html.a_input_max
                    (React.S.bind
                       offset
                       (function
                         | None -> React.S.const (`Number 0)
                         | Some max_offset ->
                           React.S.const
                             (`Number max_offset.offset_max))
                    );
                  Html.a_id plot_offset_input_id ;
                  Html.a_input_type `Range ;
                  Html.a_input_min (`Number 0) ;
                  Html.a_placeholder "offset" ;
                ] ()

let xml () =
  let plot_show_legend =
    Html.input ~a:[ Html.a_id "plot-show-legend"
                  ; Html.a_input_type `Checkbox
                  ; Html.a_class ["checkbox-control"]
                  ; Html.Unsafe.string_attrib "checked" "true"
                  ] () in
  let plot_x_axis_log_checkbox =
    Html.input ~a:[ Html.a_id "plot-x-axis-log-checkbox"
                  ; Html.a_class ["checkbox-control"]
                  ; Html.a_input_type `Checkbox
                  ] () in
  let plot_y_axis_log_checkbox =
    Html.input ~a:[ Html.a_id "plot-y-axis-log-checkbox"
                  ; Html.a_class ["checkbox-control"]
                  ; Html.a_input_type `Checkbox
                  ] () in
  let export_controls =
    Widget_export.content (configuration ())
  in
  [%html {|
  <div class="navcontent-view">
      <div class="row">
         <div id="plot-label-div" class="center-block display-header">
            Plot
         </div>
      </div>
      <div class="row">
         <div id="|}display_id{|" class="col-sm-12"> |}[ Html.entity "nbsp"]{|
         </div>
      </div>
      <div class="row">
        <div class="col-sm-1">
             |}[plot_show_legend]{| Legend
        </div>
        <div class="col-sm-2">
             Log X |}[plot_x_axis_log_checkbox]{|
             Log Y |}[plot_y_axis_log_checkbox]{|
        </div>
        <div class="col-sm-2" id="|}div_axis_select_id{|"></div>
        <div class="col-sm-2">
           <div class="input-group">
              <span class="input-group-addon">Points</span>
              |}[plot_points_input]{|
           </div>
        </div>
        <div class="col-sm-2">
           |}[plot_offset_input]{|

        </div>
      </div>
  </div>
  <div class="navcontent-controls"> |}[export_controls]{| </div> |}]

let content () : [> Html_types.div ] Html.elt list =
  [Ui_common.toggle_element (fun s -> has_plot s ) (xml ()) ]

let dimension_ref : Js_plot.plot_dimension Js.t option ref = ref None
let calculate_dimension () =
  let min_width = 400 in
  let min_height = 100 in
  let offset_width = 100 in
  let offset_height = 250 in
  let width =
    max
      min_width
      ((Js.Optdef.get
          (Dom_html.window##.innerWidth)
          (fun () -> assert false)) - offset_width)
  in
  let height =
    max
      min_height
      ((Js.Optdef.get
          (Dom_html.window##.innerHeight)
          (fun () -> assert false)) - offset_height)
  in
  let dimension =
    Js_plot.create_dimension
      ~height:height
      ~width:width
  in
  let () = dimension_ref := Some dimension
  in dimension

let get_dimension () =
  match !dimension_ref with
  | None -> calculate_dimension ()
  | Some dimension -> dimension

let simulation_info_offset_max (simulation_info : Api_types_j.simulation_info) : int =
  let plot_size = simulation_info.Api_types_j.simulation_info_output.Api_types_j.simulation_output_plot in
  max 0 (plot_size - (React.S.value point))

let update_offset (update_offset_input : bool) : unit =
  let simulation_model = React.S.value State_simulation.model in
  let simulation_info = State_simulation.t_simulation_info simulation_model in
  match simulation_info with
  | None -> ()
  | Some simulation_info ->
    if simulation_info.Api_types_j.simulation_info_progress.Api_types_j.simulation_progress_is_running then
      (* If it is running no slider because update causes jitters. *)
      set_offset None
    else
      let offset_max = simulation_info_offset_max simulation_info in
      let old_offset = React.S.value offset in
      let offset_current = match old_offset with
        | Some offset -> offset.offset_current
        | None -> offset_max in
      let () =
        if update_offset_input then
          let plot_offset_input_dom = Tyxml_js.To_dom.of_input plot_offset_input in
          let () = Common.debug (Js.string (string_of_int offset_current)) in
          let () = plot_offset_input_dom##.value := Js.string (string_of_int offset_current) in
          ()
        else
          ()
      in
      let new_offset =
        if offset_max > 0 then
          Some { offset_current = offset_current ;
                 offset_max = offset_max ; }
        else
          None
      in set_offset new_offset

let plot_limit_offset () : int =
  match React.S.value offset with
  | None ->
    let simulation_model = React.S.value State_simulation.model in
    let simulation_info = State_simulation.t_simulation_info simulation_model in
    (match simulation_info with
     | None -> 0
     | Some t -> simulation_info_offset_max t)
  | Some offset -> offset.offset_current


let plot_parameter () : Api_types_j.plot_parameter =
  let point = React.S.value point in
  { Api_types_j.plot_parameter_plot_limit =
      Some { Api_types_j.plot_limit_offset = Some (plot_limit_offset ()) ;
             Api_types_j.plot_limit_points = Some point ; } }


let update_plot (js_plot : Js_plot.observable_plot Js.t) : unit =
  State_simulation.when_ready
    ~label:__LOC__
    (fun manager ->
      let () = update_offset true in
      (manager#simulation_detail_plot (plot_parameter ())) >>=
      (Api_common.result_bind_lwt
         ~ok:(fun (plot_detail : Api_types_t.plot_detail)  ->
             let plot = plot_detail.Api_types_j.plot_detail_plot in
             let () = serialize_json := (fun _ -> Api_types_j.string_of_plot plot) in
             let () = js_plot##setDimensions(get_dimension ()) in
             let () = serialize_csv := fun _ -> Api_data.plot_values plot in
             let data : Js_plot.plot_data Js.t = Js_plot.create_data ~plot in
             let () = js_plot##setPlot(data) in
             Lwt.return (Api_common.result_ok ())
           )
      )
    )

let onload_plot_points_input
    (js_plot : Js_plot.observable_plot Js.t) : unit =
  let plot_points_input_dom : Dom_html.inputElement Js.t = Tyxml_js.To_dom.of_input plot_points_input in
  let js_point : Js.js_string Js.t = Js.string (string_of_int (React.S.value point)) in
  let () = plot_points_input_dom##.value := js_point in
  let () = plot_points_input_dom##.onchange :=
      Dom_html.handler
        (fun _ ->
           let plot_points_string : string = Js.to_string plot_points_input_dom##.value in
           let plot_points_option : int option =
             try let plot_point = int_of_string plot_points_string in
               if plot_point > 0 then
                 Some plot_point
               else
                 None
             with Failure _ -> None
           in
           let () =
             match plot_points_option with
             | Some plot_points -> set_points plot_points
             | None ->
               let plot_point : int = React.S.value point in
               let plot_point_string = string_of_int plot_point in
               let () = plot_points_input_dom##.value := Js.string plot_point_string in
               let () = set_points default_point in ()
           in
           let () = update_plot js_plot in
           Js._true)
  in
  ()

let plot_ref = ref None
let tab_is_active,set_tab_is_active = React.S.create false

let onload () =
  let plot_offset_input_dom = Tyxml_js.To_dom.of_input plot_offset_input in
  let () = Widget_export.onload (configuration ()) in
  let configuration : Js_plot.plot_configuration Js.t =
    Js_plot.create_configuration
      ~plot_div_id:display_id
      ~plot_div_select_id:div_axis_select_id
      ~plot_label_div_id:"plot-label-div"
      ~plot_style_id:"plot-svg-style"
      ~plot_show_legend_checkbox_id:"plot-show-legend"
      ~plot_x_axis_log_checkbox_id:"plot-x-axis-log-checkbox"
      ~plot_y_axis_log_checkbox_id:"plot-y-axis-log-checkbox"
  in
  let plot : Js_plot.observable_plot Js.t =
    Js_plot.create_observable_plot configuration in
  (* The elements size themselves using the div's if they are hidden
     it will default to size zero.  so they need to be sized when shown.
  *)
  let () = onload_plot_points_input plot in
  let () = plot_ref := Some plot in
  let () = Common.jquery_on
      "#navplot"
      "hide.bs.tab"
      (fun _ -> set_tab_is_active false) in
  let () = Common.jquery_on
      "#navplot"
      "shown.bs.tab"
      (fun _ ->
         let () = set_tab_is_active true in
         let simulation_model = React.S.value State_simulation.model in
         let simulation_info = State_simulation.model_simulation_info simulation_model in
         if has_plot simulation_info then
           update_plot plot
         else
           ())
  in
  let _ =
    React.S.l1
      (fun simulation_model ->
         let simulation_info = State_simulation.model_simulation_info simulation_model in
         if has_plot simulation_info then
           update_plot plot
         else
           ())
      (React.S.on
         tab_is_active State_simulation.dummy_model State_simulation.model) in
  let () =
    Ui_common.input_change
      plot_offset_input_dom
      (fun value ->
         let () = try set_offset
                        (match React.S.value offset with
                         | None -> None
                         | Some offset -> Some { offset with offset_current = int_of_string value })
           with | Failure _ -> ()
         in
         let () = update_plot plot in
         ()
      )
  in
  ()

let navli () = []

let onresize () =
  (* recalcuate size *)
  let _ = calculate_dimension () in
  let () =
    match !plot_ref with
    | None -> ()
    | Some plot ->
      (let model = React.S.value State_simulation.model in
       match State_simulation.model_simulation_info model with
       | None -> ()
       | Some _ -> update_plot plot)
  in
  ()
