RefactoringEngine = require './refactoring-engine'
RenameDialog = require './rename-view'

{CompositeDisposable} = require 'atom'

module.exports = Refactorjs =
  refactorjsView: null
  modalPanel: null
  subscriptions: null
  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'refactorjs:toggle': => @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'refactorjs:renameVariable': => @renameVariable()
    @subscriptions.add atom.commands.add 'atom-workspace', 'refactorjs:extractFunction': => @extractFunction()

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->

  toggle: ->
    console.log 'Refactorjs was toggled!'

  getContext:->
    editor = atom.workspace.getActiveTextEditor()
    bufferPositionRange = editor.getSelectedBufferRange()
    context =
      selected: editor.getSelectedText()
      text: editor.getText()
      positionStart: editor.getBuffer().characterIndexForPosition(bufferPositionRange.start)
      positionEnd: editor.getBuffer().characterIndexForPosition(bufferPositionRange.end)
    return context

  renameVariable: ->
    editor = atom.workspace.getActiveTextEditor()
    editor.moveToBeginningOfWord()
    editor.selectToEndOfWord()
    context = @getContext()
    toDialog = new RenameDialog(((to, locality)->
      modifiedText = RefactoringEngine.renameVariable(to, context)
      atom.workspace.getActiveTextEditor().setText(modifiedText)), context.selected)

  extractFunction: ->
    RefactoringEngine.extractFunction 'newName', @getContext()
