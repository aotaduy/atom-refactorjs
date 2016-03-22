RefactoringEngine = require './refactoring-engine'
RenameDialog = require './rename-view'
ExtractFunctionDialog = require './extractFunction-view'
RefactoringContext = require './refactoringContext'

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
    return new RefactoringContext(atom.workspace.getActiveTextEditor())

  renameVariable: ->
    editor = atom.workspace.getActiveTextEditor()
    editor.moveToBeginningOfWord()
    editor.selectToEndOfWord()
    context = @getContext()
    toDialog = new RenameDialog(((to, locality)->
      modifiedText = RefactoringEngine.renameVariable(to, context, locality)
      atom.workspace.getActiveTextEditor().setText(modifiedText)), context.selected)

  extractFunction: ->
    context = @getContext()
    new ExtractFunctionDialog(((to, locality)->
      modifiedText = RefactoringEngine.extractFunction to, context
      atom.workspace.getActiveTextEditor().setText(modifiedText)), 'newFunc')
