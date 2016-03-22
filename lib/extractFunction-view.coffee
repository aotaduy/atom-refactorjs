{$, TextEditorView, View} = require 'atom-space-pen-views'
path = require 'path'
oldView = null

module.exports =
class ExtractFunctionDialog extends View

  @content: (fun, name)->
    @div class: 'extract', =>
      @label 'Extract to function: '
      @input name:'fun', placeholder: 'functionName', outlet: 'fun', value: name
      @label 'Context '
      @select name:'context', outlet: 'context', value: 'Local' , =>
        @option 'Local', value: 'local'
        @option 'File', value: 'file'
      @button 'Ok', click: 'onConfirm', class: 'post-btn btn', outlet: 'okButton', type:'submit'
      @button 'Cancel', click: 'destroy', class:'post-btn btn', outlet: 'cancelButton'

  initialize: (fun, name = '') ->
    oldView?.destroy()
    oldView = this
    @callback = fun
    @fun.val(name)
    #@okButton.on 'click', => @onConfirm()
    #@cancelButton.on 'click', => @destroy()
    @panel = atom.workspace.addBottomPanel(item: this)

  onConfirm:(text) ->
    @callback(@fun.val(), @context.val())
    @destroy()

  destroy: ->
    @detach()
    @panel.destroy()


  showError: (message='') ->
    @errorMessage.text(message)
    @flashError() if message
