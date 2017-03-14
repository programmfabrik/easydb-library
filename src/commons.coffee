# these common methods are used by the plugins, developed by the vzg: gnd, geonames, gn250, gvk, georef, dante

class CustomDataTypeWithCommons extends CustomDataType

  # custom style to head
  CUI.ready =>
    style = DOM.element("style")
    style.innerHTML = ".commonPlugin_Popover { min-width:600px !important; } .commonPlugin_Input .cui-button-visual, .commonPlugin_Select .cui-button-visual { width: 100%; } .commonPlugin_Select > div { width: 100%; }"
    document.head.appendChild(style)


  #######################################################################
  # handle editorinput
  renderEditorInput: (data, top_level_data, opts) ->
    #console.error @, data, top_level_data, opts, @name(), @fullName()

    if not data[@name()]
      cdata = {
            conceptName : ''
            conceptURI : ''
        }
      data[@name()] = cdata
    else
      cdata = data[@name()]

    @__renderEditorInputPopover(data, cdata)


  #######################################################################
  # buttons, which open and close popover
  __renderEditorInputPopover: (data, cdata) ->

    layout = new HorizontalLayout
      left:
        content:
            new Buttonbar(
              buttons: [
                  new Button
                      text: ""
                      icon: 'edit'
                      group: "groupA"

                      onClick: (ev, btn) =>
                        @showEditPopover(btn, cdata, layout)

                  new Button
                      text: ""
                      icon: 'trash'
                      group: "groupA"
                      onClick: (ev, btn) =>
                        # delete data
                        cdata = {
                              conceptName : ''
                              conceptURI : ''
                        }
                        data[@name()] = cdata
                        # trigger form change
                        @__updateResult(cdata, layout)
                        Events.trigger
                          node: @__layout
                          type: "editor-changed"
                        Events.trigger
                          node: layout
                          type: "editor-changed"
              ]
            )
      center: {}
      right: {}
    @__updateResult(cdata, layout)
    layout


  #######################################################################
  # show popover and fill it with the form-elements
  showEditPopover: (btn, cdata, layout) ->

    # init xhr-object to abort running xhrs
    searchsuggest_xhr = { "xhr" : undefined }

    # set default value for count of suggestions
    cdata.countOfSuggestions = 20
    cdata_form = new Form
      data: cdata
      fields: @__getEditorFields(cdata)
      onDataChanged: =>
        @__updateResult(cdata, layout)
        @__setEditorFieldStatus(cdata, layout)
        @__updateSuggestionsMenu(cdata, cdata_form, suggest_Menu, searchsuggest_xhr)
    .start()

    # init suggestmenu
    suggest_Menu = new Menu
        element : cdata_form.getFieldsByName("searchbarInput")[0]
        use_element_width_as_min_width: true

    @popover = new Popover
      element: btn
      placement: "wn"
      class: "commonPlugin_Popover"
      pane:
        # titel of popovers
        header_left: new Label(text: 'Auswahl treffen')
        content: cdata_form
    .show()


  ########################################################################
  # check if field is empty
  # needed for editor-table-view
  isEmpty: (data, top_level_data, opts) ->
      if data[@name()]?.conceptName
          false
      else
          true

  #######################################################################
  # is called, when record is being saved by user
  getSaveData: (data, save_data, opts) ->
    cdata = data[@name()] or data._template?[@name()]

    switch @getDataStatus(cdata)
      when "invalid"
        throw InvalidSaveDataException

      when "empty"
        save_data[@name()] = null

      when "ok"
        save_data[@name()] =
          conceptName: cdata.conceptName.trim()
          conceptURI: cdata.conceptURI.trim()


  #######################################################################
  # update result in Masterform
  __updateResult: (cdata, layout) ->
    btn = @__renderButtonByData(cdata)
    layout.replace(btn, "right")


  #######################################################################
  # if something in form is in/valid, set this status to masterform
  __setEditorFieldStatus: (cdata, element) ->
    switch @getDataStatus(cdata)
      when "invalid"
        element.addClass("cui-input-invalid")
      else
        element.removeClass("cui-input-invalid")

    Events.trigger
      node: element
      type: "editor-changed"

    @

  #######################################################################
  # renders details-output of record
  renderDetailOutput: (data, top_level_data, opts) ->
    @__renderButtonByData(data[@name()])


  #######################################################################
  # checks the form and returns status
  getDataStatus: (cdata) ->
    if (cdata)
        if cdata.conceptURI and cdata.conceptName
          # check url for valididy
          uriCheck = CUI.parseLocation(cdata.conceptURI)

          nameCheck = if cdata.conceptName then cdata.conceptName.trim() else undefined

          if uriCheck and nameCheck
            return "ok"

          if cdata.conceptURI.trim() == '' and cdata.conceptName.trim() == ''
            return "empty"

          return "invalid"
        else
          cdata = {
                conceptName : ''
                conceptURI : ''
            }
          return "empty"
    else
      cdata = {
            conceptName : ''
            conceptURI : ''
        }
      return "empty"
  #######################################################################
  # render Options for Datamodel as empty
  renderCustomDataOptionsInDatamodel: (custom_settings) ->
    new Label(text: "Keine Optionen möglich")