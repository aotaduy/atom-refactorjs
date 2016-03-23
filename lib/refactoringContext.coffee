engine = require './refactoring-engine'

module.exports =
class RefactoringContext
  constructor: (editor) ->
    @initializeFromAtom editor

  initializeFromAtom: (editor) ->
    bufferPositionRange = editor.getSelectedBufferRange()
    @selected =  editor.getSelectedText()
    @text = editor.getText()
    @positionStart =  editor.getBuffer().characterIndexForPosition(bufferPositionRange.start)
    @positionEnd =  editor.getBuffer().characterIndexForPosition(bufferPositionRange.end)
    @scopeAnalysis = engine.getAnalysis(@text) #Create AST and scope for entire text

  replaceSelectionWith: (string) ->
    begining = @text.substr(0, @positionStart)
    end = @text.substr(@positionEnd, @text.length)
    "#{begining}\n#{string}\n#{end}"

  getFunctionScope: ->
    @functionScope = @functionScope || engine.findScopeContaining @positionStart, @scopeAnalysis.currentScope
