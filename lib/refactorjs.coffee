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
    @subscriptions.add atom.commands.add 'atom-workspace', 'refactorjs:renameVariable': => @renameVariable()
    @subscriptions.add atom.commands.add 'atom-workspace', 'refactorjs:extractFunction': => @extractFunction()
    @subscriptions.add atom.commands.add 'atom-workspace', 'refactorjs:inlineFunction': => @inlineFunction()

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->


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
    new ExtractFunctionDialog(((to, locality) ->
      try
        modifiedText = RefactoringEngine.extractFunction to, context
        atom.workspace.getActiveTextEditor().setText(modifiedText)
      catch error
        console.log(error)
        atom.notifications.addWarning 'Unable to execute refactoring check syntax of your selection', detail: error.message
        ), 'newFunc')
  inlineFunction: ->
    context = @getContext()
    modifiedText = RefactoringEngine.inlineFunction context
    atom.confirm
      message: "Inline Function: #{context.functionScope.block.id.name}"
      detailedMessage: 'Please Confirm'
      buttons:
        Ok: -> atom.workspace.getActiveTextEditor().setText(modifiedText)
        Cancel: -> 'Cancel'
