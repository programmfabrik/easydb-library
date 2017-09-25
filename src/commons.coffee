# these common classes + methods are used by the plugins, developed by the vzg: gnd, geonames, gn250, gvk, georef, dante

class CustomDataTypeWithCommons extends CustomDataType

  # custom style to head
  CUI.ready =>
    style = DOM.element("style")
    style.innerHTML = ".commonPlugin_Popover { min-width:600px !important; min-height: 200px !important; } .commonPlugin_Input .cui-button-visual, .commonPlugin_Select .cui-button-visual { width: 100%; } .commonPlugin_Select > div { width: 100%; }"
    document.head.appendChild(style)

  initData: (data) ->
      if not data[@name()]
          cdata = {}
          data[@name()] = cdata
      else
          cdata = data[@name()]

      if not cdata.url
          cdata.url = ""

      cdata

  # returns a map for search tokens, containing name and value strings.
  getQueryFieldBadge: (data) =>
      # CUI.error "getQueryFieldBadge", data
      if data["#{@name()}:unset"]
          value = $$("text.column.badge.without")
      else
          value = data[@name()]

      name: @nameLocalized()
      value: value


  supportsFacet: ->
      true


  getFacet: (opts) ->
      opts.field = @
      new CustomDataTypeCommonFacet(opts)


  # returns markup to display in expert search
  renderSearchInput: (data, opts={}) ->
      search_token = new SearchToken
          column: @
          data: data
          fields: opts.fields
      .getInput().DOM


  getFieldNamesForSearch: ->
      @getFieldNames()


  getFieldNamesForSuggest: ->
      @getFieldNames()


  getFieldNames: ->

      field_names = [
          @fullName()+".conceptURI"
          @fullName()+".conceptName"
      ]

      #for lang in ez5.session.getPref("search_languages")
      #  field_names.push(@fullName()+".text."+lang)

      field_names


	# returns a search filter suitable to the search array part
	# of the request, the data to be search is in data[key] plus
	# possible additions, which should be stored in key+":<additional>"

  getSearchFilter: (data, key=@name()) ->

      if data[key+":unset"]
          filter =
              type: "in"
              fields: [ @fullName()+".conceptName" ]
              in: [ null ]
          filter._unnest = true
          filter._unset_filter = true
          return filter

      filter = super(data, key)
      if filter
          return filter

      if isEmpty(data[key])
          return

      val = data[key]
      [str, phrase] = Search.getPhrase(val)

      switch data[key+":type"]
          when "token", "fulltext", undefined
              filter =
                  type: "match"
                  # mode can be fulltext, token or wildcard
                  mode: data[key+":mode"]
                  fields: @getFieldNamesForSearch()
                  string: str
                  phrase: phrase

          when "field"
              filter =
                  type: "in"
                  fields: @getFieldNamesForSearch()
                  in: [ str ]

      filter


  #######################################################################
  # handle editorinput
  renderEditorInput: (data, top_level_data, opts) ->

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

    layout = new CUI.HorizontalLayout
      left:
        content:
            new CUI.Buttonbar(
              buttons: [
                  new CUI.Button
                      text: ""
                      icon: 'edit'
                      group: "groupA"

                      onClick: (ev, btn) =>
                        @showEditPopover(btn, cdata, layout)

                  new CUI.Button
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
    cdata_form = new CUI.Form
      data: cdata
      fields: @__getEditorFields(cdata)
      onDataChanged: =>
        @__updateResult(cdata, layout)
        @__setEditorFieldStatus(cdata, layout)
        @__updateSuggestionsMenu(cdata, cdata_form, suggest_Menu, searchsuggest_xhr)
    .start()

    # init suggestmenu
    suggest_Menu = new CUI.Menu
        element : cdata_form.getFieldsByName("searchbarInput")[0]
        use_element_width_as_min_width: true

    @popover = new CUI.Popover
      element: btn
      placement: "wn"
      class: "commonPlugin_Popover"
      pane:
        # titel of popovers
        header_left: new CUI.Label(text: 'Auswahl treffen')
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
    if opts.demo_data
      # return demo data here
      return {
        conceptName : 'Example'
        conceptURI : 'https://example.com'
      }

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
          _fulltext:
                  text: cdata.conceptName.trim()
                  string: cdata.conceptURI.trim()


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
  # zeige die gewählten Optionen im Datenmodell unter dem Button an
  getCustomDataOptionsInDatamodelInfo: (custom_settings) ->
    if Object.keys(custom_settings).length == 0
      ['Ohne Optionen']



class CustomDataTypeCommonFacet extends FieldFacet

  requestFacetWithLimit: ->
      limit: @getLimit()
      field: @_field.fullName()+".conceptName"
      sort: "term"
      type: "term"

  getObjects: (key=@name(), data=@data()) ->
      data[key]?.terms or []

  renderObjectText: (object) ->
      object.term

  getObjectPath: (obj) ->
      [obj.term]

  name: ->
      "cdt_link"

  name: ->
      @_field.fullName()+".conceptName"

  requestSearchFilter: (obj) ->
      bool: "must"
      fields: [ @_field.fullName()+".conceptName" ]
      type: "in"
      in: [ obj.term ]
