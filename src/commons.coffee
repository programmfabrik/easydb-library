# these common classes + methods are used by the plugins, developed by the vzg: gnd, geonames, gn250, gvk, georef, dante, getty, tna_discovery

class CustomDataTypeWithCommons extends CustomDataType

  # init data
  initData: (data) ->
      if not data[@name()]
          cdata = null
          data[@name()] = cdata
      else
          cdata = data[@name()]

      if not cdata.url
          cdata.url = ""

      cdata

  renderFieldAsGroup: ->
    return false

  renderRowAsBlock: (data, top_level_data, opts) ->
    false

  # returns a map for search tokens, containing name and value strings.
  getQueryFieldBadge: (data) =>
      if data["#{@name()}:unset"]
          value = $$("text.column.badge.without")
      else
          value = data[@name()]

      name: @nameLocalized()
      value: value


  supportsStandard: ->
      true

  supportsPrinting: ->
      true

  supportsFacet: ->
      true


  getFacet: (opts) ->
      opts.field = @
      new CustomDataTypeCommonFacet(opts)


  # provide a sort function to sort your data
  getSortFunction: ->
      (a, b) =>
          CUI.util.compareIndex(a[@name()]?.conceptName or 'zzz', b[@name()]?.conceptName or 'zzz')

  # Enable sort
  hasRenderForSort: ->
    return true

  sortExtraOpts: ->
    return [
      {
        text: "conceptName"
        value: "conceptName"
      }
      {
        text: "conceptURI"
        value: "conceptURI"
      }
    ]

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

      if CUI.util.isEmpty(data[key])
          return

      val = data[key]
      [str, phrase] = Search.getPhrase(val)

      switch data[key+":type"]
          when "token", "fulltext", undefined
              filter =
                  type: "match"
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

    name = @name(opts)
    if not data[name]
      data[name] = {
            conceptName : ''
            conceptURI : ''
        }

    @__renderEditorInputPopover(data, data[name], opts)


  #######################################################################
  # buttons, which opens and closes popover+menu
  __renderEditorInputPopover: (data, cdata, opts = {}, customButtonBarEntrys = false) ->
    that = @
    @.dotsButtonMenu = {}
    layout = {}

    classNameForBurgerMenuButton = 'pluginDirectSelectEditSearch'
    if ez5.version("6")
      classNameForBurgerMenuButton = 'pluginDirectSelectEditSearchFylr'
    else if ez5.version("5")
      classNameForBurgerMenuButton = 'pluginDirectSelectEditSearch'
            
    # build layout for editor
    layout = new CUI.HorizontalLayout
        class: 'customPluginEditorLayout'
        center:
          class: ''
        right:
          content:
              new CUI.Buttonbar
                buttons: [
                  new CUI.Button
                    text: ''
                    icon: new CUI.Icon(class: "fa-ellipsis-v")
                    class: classNameForBurgerMenuButton
                    # show "dots"-menu on click on 3 vertical dots
                    onClick: (e, dotsButton) =>
                      that.dotsButtonMenu = new CUI.Menu
                          class: "customDataTypeCommonsMenu"
                          element : dotsButton
                          menu_items = [
                              #search
                              text: $$('custom.data.type.commons.controls.search.label')
                              value: 'search'
                              icon_left: new CUI.Icon(class: "fa-search")
                              onClick: (e2, btn2) ->
                                that.showEditPopover(dotsButton, data, cdata, layout, opts)
                                that.dotsButtonMenu.hide()
                          ]

                          if typeof that.__getAdditionalTooltipInfo == "function"
                            detailinfo =
                              #detailinfo
                              text: $$('custom.data.type.commons.controls.detailinfo.label')
                              value: 'detail'
                              icon_left: new CUI.Icon(class: "fa-info-circle")
                              disabled: that.isEmpty(data, 0, opts)
                              onClick: (eDetailInfo, btnDetailInfo) ->
                                tooltip = new CUI.Tooltip
                                  element: btnDetailInfo
                                  placement: 'w'
                                  markdown: true
                                  show_ms: 1000
                                  hide_ms: 200
                                  content: (tooltip) ->
                                    if !that.isEmpty(data, 0, opts)
                                      # get details-data
                                      encodedURI = encodeURIComponent(cdata.conceptURI)
                                      extendedInfo_xhr = { "xhr" : undefined }
                                      that.__getAdditionalTooltipInfo(encodedURI, tooltip, extendedInfo_xhr)
                                      # loader, until details are xhred
                                      new CUI.Label(icon: "spinner", text: $$('custom.data.type.commons.modal.form.popup.loadingstring'))
                                tooltip.show()
                                # hide tooltip + menu on mouseaction
                                CUI.Events.listen
                                  type: ["click", "dblclick", "mouseout"]
                                  capture: true
                                  node: btnDetailInfo
                                  only_once: true
                                  call: (ev) =>
                                    that.dotsButtonMenu.hide()

                            menu_items.push detailinfo
                          uriCall =
                              # call uri
                              text: $$('custom.data.type.commons.controls.calluri.label')
                              value: 'uri'
                              icon_left: new CUI.Icon(class: "fa-external-link")
                              disabled: that.isEmpty(data, 0, opts) || ! CUI.parseLocation(cdata.conceptURI)
                              onClick: ->
                                window.open cdata.conceptURI, "_blank"
                                that.dotsButtonMenu.hide()
                          menu_items.push uriCall
                          deleteClear =
                              #delete / clear
                              text: $$('custom.data.type.commons.controls.delete.label')
                              value: 'delete'
                              name: 'deleteValueFromDANTEPlugin'
                              class: 'deleteValueFromDANTEPlugin'
                              icon_left: new CUI.Icon(class: "fa-trash")
                              disabled: that.isEmpty(data, 0, opts)
                              onClick: ->
                                cdata = {
                                    conceptName : ''
                                    conceptURI : ''
                                }
                                data[that.name(opts)] = cdata
                                that.__updateResult(cdata, layout, opts)
                                that.dotsButtonMenu.hide()
                          menu_items.push deleteClear

                          # add custom buttons, if given
                          if customButtonBarEntrys?.length > 0
                            menu_items.push customButtonBarEntrys...

                          itemList =
                            items: menu_items
                      that.dotsButtonMenu._auto_close_after_click = false
                      that.dotsButtonMenu.setItemList(itemList)
                      that.dotsButtonMenu.show()
                ]

    # present the layout upwards for possible cases
    @.layout = layout

    # other plugins can trigger layout-rebuild by deletion of data-value
    CUI.Events.registerEvent
      type: "custom-deleteDataFromPlugin"
      bubble: false

    CUI.Events.listen
      type: "custom-deleteDataFromPlugin"
      instance: that
      node: layout
      call: =>
        for key of cdata
          delete cdata[key]
        data[that.name(opts)] = cdata
        opts.deleteDataFromPlugin = true
        that.__updateResult(cdata, layout, opts)

    @__updateResult(cdata, layout, opts)

    opts.initialcallfrompoolmanager = false

    layout


  #######################################################################
  # show popover and fill it with the form-elements
  showEditPopover: (btn, data, cdata, layout, opts) ->
    that = @

    suggest_Menu

    # init xhr-object to abort running xhrs
    searchsuggest_xhr = { "xhr" : undefined }

    # set default value for count of suggestions
    cdata.countOfSuggestions = 50
    cdata_form = new CUI.Form
      class: 'cdtFormWithPadding'
      data: cdata
      fields: that.__getEditorFields(cdata)
      onDataChanged: (data, elem) =>
        @__updateResult(cdata, layout, opts)
        @__setEditorFieldStatus(cdata, layout)
        @__updateSuggestionsMenu(cdata, cdata_form, data.searchbarInput, elem, suggest_Menu, searchsuggest_xhr, layout, opts)
    .start()

    # init suggestmenu
    suggest_Menu = new CUI.Menu
        element: cdata_form.getFieldsByName("searchbarInput")[0]
        use_element_width_as_min_width: true
        class: "customDataTypeCommonsMenu"

    @popover = new CUI.Popover
      element: btn
      placement: "wn"
      class: "commonPlugin_Popover"
      pane:
        # titel of popovers
        header_left: new CUI.Label(text: $$('custom.data.type.commons.popover.choose.label'))
        content: cdata_form
    .show()


  ########################################################################
  # check if field is empty
  isEmpty: (data, top_level_data, opts={}) ->
      if opts?.mode == "expert"
          # check input in expert search
          if typeof data[@name(opts)] == 'object'
            return CUI.util.isEmpty(data[@name(opts)]?)
          else
            return CUI.util.isEmpty(data[@name(opts)]?.trim())

      return not data[@name(opts)]?.conceptName

  #######################################################################
  # is called, when record is being saved by user
  getSaveData: (data, save_data, opts) ->
    that = @

    if opts.demo_data
      return {
        conceptName : 'Example'
        conceptURI : 'https://example.com'
      }

    cdata = data[@name(opts)] or data._template?[@name(opts)]
    switch @getDataStatus(cdata)
      when "invalid"
        if opts.copy
            save_data[@name(opts)] = null
        else
            throw new InvalidSaveDataException()

      when "empty"
        save_data[@name(opts)] = null

      when "ok"

        # if _fulltext is already set, leave it, else set conceptName
        conceptFulltext = {}
        if cdata?._fulltext
          if cdata._fulltext?.string
            if cdata._fulltext?.string != ''
              conceptFulltext.string = cdata._fulltext.string
          if cdata._fulltext?.l10ntext
            if cdata._fulltext.l10ntext
              conceptFulltext.l10ntext = cdata._fulltext.l10ntext
          if cdata._fulltext?.text
            if cdata._fulltext.text
              conceptFulltext.text = cdata._fulltext.text
        else
          conceptFulltext.text = cdata.conceptName.trim()

        # if _standard is already set, leave it
        conceptStandard = {}
        if cdata?._standard
          if cdata._standard?.l10ntext
            if cdata._standard.l10ntext
              conceptStandard.l10ntext = cdata._standard.l10ntext
          else
            # only set .text, if l10ntext is not set (else easydb-error!)
            if cdata._standard?.text
              if cdata._standard?.text != ''
                conceptStandard.text = cdata._standard.text
          if cdata._standard?.geo
            if cdata._standard.geo
              conceptStandard.geo = cdata._standard.geo 

	       # save the frontend-language (display-purposes)
        frontendLanguages = ez5.loca.getLanguage()
        frontendLanguages = frontendLanguages.split('-')
        frontendLanguage = frontendLanguages[0]

        # save the eventually manual chosen label
        conceptNameChosenByHand = false
        if cdata?.conceptNameChosenByHand
          if cdata.conceptNameChosenByHand == true
            conceptNameChosenByHand = true

        # save the eventually applied hierarchie
        conceptNameWithHierarchie = false
        if cdata?.conceptNameWithHierarchie
          if cdata.conceptNameWithHierarchie == true
            conceptNameWithHierarchie = true
            
        # build savedata
        save_data[@name(opts)] =
          conceptName: cdata.conceptName.trim()
          conceptURI: cdata.conceptURI.trim()
          frontendLanguage: frontendLanguage
          _fulltext: conceptFulltext
          _standard: conceptStandard

        # hierarchical ancestors given?
        if cdata?.conceptAncestors
          if cdata.conceptAncestors.length > 0
            if Array.isArray cdata.conceptAncestors
              cdata.conceptAncestors = cdata.conceptAncestors.join(' ')
            save_data[@name(opts)]['conceptAncestors'] = cdata.conceptAncestors

        # conceptSource set?
        if cdata?.conceptSource
          if typeof cdata.conceptSource == 'string'
            if cdata.conceptSource.length > 0
              save_data[@name(opts)]['conceptSource'] = cdata.conceptSource

        # conceptGeoJSON set?
        if cdata?.conceptGeoJSON
          if typeof cdata.conceptGeoJSON == 'object'
            if Object.keys(cdata.conceptGeoJSON).length > 0
              save_data[@name(opts)]['conceptGeoJSON'] = cdata.conceptGeoJSON
				
        # conceptname choosen manually?
        if cdata?.conceptNameChosenByHand
          if cdata.conceptNameChosenByHand == true
            save_data[@name(opts)]['conceptNameChosenByHand'] = true

        # conceptname with applied hierarchie
        if cdata?.conceptNameWithHierarchie
          if cdata.conceptNameWithHierarchie == true
            save_data[@name(opts)]['conceptNameWithHierarchie'] = true
            
        # add facet if exists
        if cdata?.facetTerm
          save_data[@name(opts)]['facetTerm'] = cdata.facetTerm

  #######################################################################
  # update result in Masterform
  __updateResult: (cdata, layout, opts) ->
    that = @
    if opts.data
      opts.data[that.name(opts)] = cdata
        
    # check if display-layout should be oneline
    onelineDisplay = false
    if @FieldSchema?.custom_settings?.editor_display?.value == 'condensed' || opts?.custom_settings?.editor_display?.value == 'condensed'
      onelineDisplay = true
    
    # if field is not empty
    if cdata?.conceptURI
      # die uuid einkürzen..
      displayURI = cdata.conceptURI
      if displayURI.length > 20
        displayURI = displayURI.replace('http://', '')
        displayURI = displayURI.replace('https://', '')
      if displayURI.length > 30
        displayURI = displayURI.replace('uri.gbv.de/terminology/', '…/')

      # default display
      topContent = 
          content: 
              new CUI.Label
                text: cdata.conceptName
                multiline: true  
                
      # condensed display
      if onelineDisplay && typeof that.__getAdditionalTooltipInfo == "function"
         onelineButtonbar =  new CUI.Buttonbar
                                  buttons: [
                                        new CUI.Label
                                          centered: false
                                          text: cdata.conceptName
                                          multiline: true  

                                        new CUI.ButtonHref
                                          name: "outputButtonHref"
                                          class: "pluginResultButton"
                                          appearance: "link"
                                          size: "normal"
                                          href: cdata.conceptURI
                                          target: "_blank"
                                          tooltip:
                                            markdown: true
                                            placement: 'nw'
                                            content: (tooltip) ->
                                              extendedInfo_xhr = { "xhr" : undefined }
                                              # get jskos-details-data
                                              encodedURI = encodeURIComponent(cdata.conceptURI)
                                              that.__getAdditionalTooltipInfo(encodedURI, tooltip, extendedInfo_xhr)
                                              # loader, until details are xhred
                                              new CUI.Label(icon: "spinner")
                                  ]
         onelineButtonbar.DOM.style.maxWidth = '92%'
         topContent = 
             content: 
                # output Button with Name of picked dante-Entry and URI
                onelineButtonbar

      info = new CUI.VerticalLayout
        class: 'ez5-info_commonPlugin'
        top: topContent

        bottom: if ! onelineDisplay
          content:
            new CUI.Button
              name: "outputButtonHref"
              appearance: "flat"
              size: "normal"
              text: displayURI
              tooltip:
                markdown: true
                placement: 'w'
                content: (tooltip) ->
                  # get details-data
                  encodedURI = encodeURIComponent(cdata.conceptURI)
                  extendedInfo_xhr = { "xhr" : undefined }
                  if typeof that.__getAdditionalTooltipInfo == "function"
                    that.__getAdditionalTooltipInfo(encodedURI, tooltip, extendedInfo_xhr)
                    # loader, unteil details are xhred
                    new CUI.Label(icon: "spinner", text: $$('custom.data.type.commons.modal.form.popup.loadingstring'))
              onClick: (evt,button) =>
                  window.open cdata.conceptURI, "_blank"

      layout.replace(info, 'center')
      layout.addClass('ez5-linked-object-edit')
      options =
        class: 'ez5-linked-object-container'
      layout.__initPane(options, 'center')

    # if field is empty, display searchfield
    if ! cdata?.conceptURI
      suggest_Menu_directInput

      inputX = new CUI.Input
                  class: "pluginDirectSelectEditInput"
                  undo_and_changed_support: false
                  name: "directSelectInput"
                  content_size: false
                  onKeyup: (input) =>
                    # do suggest request and show suggestions
                    searchstring = input.getValueForInput()
                    if typeof that.__updateSuggestionsMenu == "function"
                      @__updateSuggestionsMenu(cdata, 0, searchstring, input, suggest_Menu_directInput, searchsuggest_xhr, layout, opts)

      # if not called from poolmanagerplugin the first time
      #   (otherwise "already rendered", because DataFieldProxy renders it again)
      rendered = false
      if ! opts?.callfrompoolmanager
        rendered = true
        inputX.render()

      if opts.initialcallfrompoolmanager == false && rendered == false
        inputX.render()

      opts.initialcallfrompoolmanager = false

      # init suggestmenu
      suggest_Menu_directInput = new CUI.Menu
          element : inputX
          use_element_width_as_min_width: true
          class: "customDataTypeCommonsMenu"

      # init xhr-object to abort running xhrs
      searchsuggest_xhr = { "xhr" : undefined }

      layout.replace(inputX, 'center')
      layout.removeClass('ez5-linked-object-edit')
      options =
        class: ''
      layout.__initPane(options, 'center')

    # if deleted from another plugin, do NOT trigger, because that could lead in an endless loop
    if ! opts.deleteDataFromPlugin
      # did data change?
      that.__setEditorFieldStatus(cdata, layout)


  #######################################################################
  # if something in form is in/valid, set this status to masterform
  __setEditorFieldStatus: (cdata, element) ->
    switch @getDataStatus(cdata)
      when "invalid"
        element.addClass("cui-input-invalid")
      else
        element.removeClass("cui-input-invalid")

    CUI.Events.trigger
      node: element
      type: "editor-changed"

    CUI.Events.trigger
      node: element
      type: "data-changed"

    @

  #######################################################################
  # renders details-output of record
  renderDetailOutput: (data, top_level_data, opts) ->
    @__renderButtonByData(data[@name(opts)])


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
      return "empty"


  #######################################################################
  # zeige die gewählten Optionen im Datenmodell unter dem Button an
  #getCustomDataOptionsInDatamodelInfo: (custom_settings) ->
  #  if Object.keys(custom_settings).length == 0
  #    ['Ohne Optionen']


class CustomDataTypeCommonFacet extends FieldFacet

  initOpts: ->
      super()
      @addOpts
          field:
              mandatory: true
              check: Field

  requestFacetWithLimit: (obj) ->
      limit: @getLimit()
      field: @_field.fullName()+".conceptName"
      sort: "count"
      type: "term"

  getObjects: (key=@name(), data=@data()) ->
      data[key]?.terms or []

  renderObjectText: (object) ->
      object.term

  getObjectPath: (obj) ->
      [obj.term]

  name: ->
      @_field.fullName()+".conceptName"

  requestSearchFilter: (obj) ->
      bool: "must"
      fields: [ @_field.fullName()+".conceptName" ]
      type: "in"
      in: [ obj.term ]

  # Let the frontend sort the facets, there are facets that could not be sorted by the backend
  # This can be overridden by the plugin to sort the objects in a different way
  getObjectsSorted: () ->
    return super()
