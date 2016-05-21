module ApiTypes = ApiTypes_j
module Html5 = Tyxml_js.Html5
module UIState = Ui_state

open Js_plot

let div_id = "plot-div"
let export_filename_id = "plot-export-filename"
let export_button_id =  "plot-export-button"
let export_format_id = "export-file-format"
let div_id = "plot-div"

let state_plot state = match state with
    None -> None
  | Some state -> state.ApiTypes.plot

let content =
  let plot_show_legend =
    Html5.input ~a:[ Html5.a_id "plot-show-legend"
                   ; Html5.a_input_type `Checkbox
                   ; Html5.a_class ["checkbox-control"]
                   ; Html5.Unsafe.string_attrib "checked" "true"
                   ] () in
  let plot_x_axis_log_checkbox =
    Html5.input ~a:[ Html5.a_id "plot-x-axis-log-checkbox"
                   ; Html5.a_class ["checkbox-control"]
                   ; Html5.a_input_type `Checkbox
                   ] () in
  let plot_y_axis_log_checkbox =
    Html5.input ~a:[ Html5.a_id "plot-y-axis-log-checkbox"
                   ; Html5.a_class ["checkbox-control"]
                   ; Html5.a_input_type `Checkbox
                   ] () in
  let export_controls =
    Display_common.export_controls
      export_format_id
      export_filename_id
      export_button_id
  in
  <:html5<<div>
      <div class="row">
          <div id="plot-label-div" class="center-block display-header">
          Plot
          </div>
      </div>
      <div class="row">
        <div id="plot-control" class="col-sm-4">
          <ul class="list-group">
            <li class="list-group-item">
              <h4 class="list-group-litem-heading">Observables</h4>
              <div id="plot-controls-div"/>
            </li>
            <li class="list-group-item">
              <h4 class="list-group-item-heading">Settings</h4>
                <div class="checkbox-control">
                   $plot_show_legend$ Legend
                </div>
                <div class="checkbox-control">
                   $plot_x_axis_log_checkbox$ X Axis Log
                </div>
                <div class="checkbox-control">
                   $plot_y_axis_log_checkbox$ Y Axis Log
                </div>
            </li>
          </ul>
        </div>
        <div id="plot-div" class="col-sm-8"></div>
      </div>
      $export_controls$
  </div> >>

let navcontent =
  [ Html5.div
      ~a:[Tyxml_js.R.Html5.a_class
             (React.S.bind
                UIState.model_runtime_state
                (fun state ->
                  React.S.const
                    (match state_plot state with
                      None -> ["hidden"]
                    | Some _ -> ["show"])
                )
             )]
      [ content ]
  ]

let state_plot state = match state with
    None -> None
  | Some state -> state.ApiTypes.plot

let update_plot
    (plot : observable_plot Js.t)
    (data : ApiTypes.plot option) : unit =
  match data with
    None -> ()
  | Some data ->
    let div : Dom_html.element Js.t =
      Js.Opt.get (Display_common.document##getElementById
                    (Js.string div_id))
        (fun () -> assert false) in
    let width = max 400 (div##offsetWidth - 20)  in
    let height = width/2 in
    let dimension =
      Js_plot.create_dimension
        ~height:height
        ~width:width
    in
    let () = plot##setDimensions(dimension) in
    let data : plot_data Js.t = Js_plot.create_data data in
    plot##setPlot(data)

let onload () =
  let configuration : plot_configuration Js.t =
    Js_plot.create_configuration
      ~plot_div_id:div_id
      ~plot_label_div_id:"plot-label-div"
      ~plot_style_id:"plot-svg-style"
      ~plot_show_legend_checkbox_id:"plot-show-legend"
      ~plot_x_axis_log_checkbox_id:"plot-x-axis-log-checkbox"
      ~plot_y_axis_log_checkbox_id:"plot-y-axis-log-checkbox"
      ~plot_controls_div_id:"plot-controls-div"
  in
  let plot : observable_plot Js.t =
    Js_plot.create_observable_plot configuration in
  let () =
    Display_common.save_plot_ui
      (fun f -> let filename = Js.string f in
                let () = plot##setPlotName(filename) in
                plot##handlePlotTSV(())
      )
      "kappa plot"
      export_button_id
      export_filename_id
      export_format_id
      div_id
      "tsv"
  in
  (* The elements size themselves using the div's if they are hidden
     it will default to size zero.  so they need to be sized when shown.
  *)
  let () = Common.jquery_on
    "#navgraph"
    "shown.bs.tab"
    (fun _ ->
      match (React.S.value UIState.model_runtime_state) with
        None -> ()
      | Some state -> update_plot plot state.plot)
  in
  let _ =
    React.S.l1
      (fun state -> match state with
        None -> ()
      | Some state -> update_plot plot state.ApiTypes.plot)
      UIState.model_runtime_state
  in
  ()

let navli = []