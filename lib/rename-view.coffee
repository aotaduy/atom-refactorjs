{$, TextEditorView, View} = require 'atom-space-pen-views'
path = require 'path'
oldView = null

module.exports =
class RenameDialog extends View

  @content: (fun, name)->
    @div class: 'rename', =>
      @label 'Rename ' + name + ' to: '
      @input name:'variable', placeholder: 'Variable', outlet: 'to', value: name
      @label 'Context '
      @select name:'context', outlet: 'context', value: 'Local' , =>
        @option 'Local', value: 'local'
        @option 'File', value: 'file'
      @button 'Ok', click: 'onConfirm', class: 'post-btn btn', outlet: 'okButton'
      @button 'Cancel', click: 'cancel', class:'post-btn btn', outlet: 'cancelButton'

  initialize: (fun, name = '') ->
    oldView?.destroy()
    oldView = this
    @callback = fun
    @to.val(name)
    @okButton.on 'click', => @onConfirm()
    @cancelButton.on 'click', => @destroy()
    
    @panel = atom.workspace.addBottomPanel(item: this)

  onConfirm:(text) ->
    @callback(@to.val(), @context.val())
    @destroy()

  destroy: ->
    @detach()
    @panel.destroy()


  showError: (message='') ->
    @errorMessage.text(message)
    @flashError() if message
