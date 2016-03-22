{$, TextEditorView, View} = require 'atom-space-pen-views'
path = require 'path'
oldView = null

module.exports =
class ExtractFunctionDialog extends View

  @content: (fun, name)->
    @div class: 'extract', =>
      @label 'Extract to function: '
      @input name:'fun', placeholder: 'functionName', outlet: 'fun', value: name
      @button 'Ok', click: 'onConfirm', class: 'post-btn btn', outlet: 'okButton', type:'submit'
      @button 'Cancel', click: 'destroy', class:'post-btn btn', outlet: 'cancelButton'

  initialize: (fun, name = '') ->
    oldView?.destroy()
    oldView = this
    @callback = fun
    @fun.val(name)
    @panel = atom.workspace.addBottomPanel(item: this)

  onConfirm:(text) ->
    @callback(@fun.val())
    @destroy()

  destroy: ->
    @detach()
    @panel.destroy()


  showError: (message='') ->
    @errorMessage.text(message)
    @flashError() if message
