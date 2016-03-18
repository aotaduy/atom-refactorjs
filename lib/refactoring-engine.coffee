escope = require 'escope'
esprima = require 'esprima'
estraverse = require 'estraverse'
escodegen = require 'escodegen'
globals = require 'globals'
allGlobals = new Set()
Object.keys(globals).forEach (globalCategory) ->
  Object.keys(globals[globalCategory]).forEach (globalName) ->
    allGlobals.add globalName

class RefactoringEngine
  parse: (src) ->
    ast = esprima.parse src, comment: true, range: true, tokens: true
    escodegen.attachComments ast, ast.comments, ast.tokens


  getAnalysis:(src) ->
    ast = @parse(src)
    scopeManager = escope.analyze ast

    answer =
      ast: ast,
      scopeManager: scopeManager
      currentScope: scopeManager.acquire ast
    return answer

  renameVariable: (to, context) ->
    console.log 'renaming variable', context.selected , ' to ', to
    analysis = @getAnalysis(context.text)
    newAST = estraverse.replace analysis.ast, enter:(node) ->
      if node.type == 'Identifier' && node.name == from
        node.name = to
        return node
    return escodegen.generate newAST, comment: true

  filterGlobals: (references) ->
    references
      .filter (reference) ->
        !allGlobals.has(reference.identifier.name)

  paramtersForReferences: (references) ->
    names = references.map (reference) ->
      reference.identifier.name
    names.filter (name, index) ->
      names.indexOf(name) == index

  getParentScopeNode: (context) ->
    analysis = @getAnalysis(context.text)
    scope = analysis.currentScope
    scope = @findScopeContaining(context.positionStart, scope)
    scope.block

  findScopeContaining: (position, scope) ->
    self = this
    if scope.block.range[0] < position && position< scope.block.range[1]
      filtered = scope.childScopes.filter (child) ->
        self.findScopeContaining(position, child) != null
      answer = if filtered.length == 0  then scope else filtered[0]
    else
      answer = null

    return answer

  extractFunction: (name, context) ->
    analysis = @getAnalysis(context.selected) #Handle Parse Errors via catch
    console.log(analysis)
    unreferenced = analysis.currentScope.references
      .filter (reference) ->
        !analysis.currentScope.variables.some (variable) ->
          variable.name == reference.identifier.name
    unreferenced = @filterGlobals unreferenced
    parameters = @paramtersForReferences(unreferenced).join(', ')
    call = "function #{name}(#{parameters});"
    source = "function #{name}(#{parameters}){\n#{context.selected}\n}"
    console.log(source)
    generatedAst = @parse(source)
    parentScopeNode = @getParentScopeNode(context)
    parentScopeNode.body.body.push(generatedAst)
    console.log(escodegen.generate parentScopeNode, comment: true)


module.exports = new RefactoringEngine
