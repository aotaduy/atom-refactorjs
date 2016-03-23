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
      currentScope: scopeManager.acquire ast, optimistic: true
    return answer

  renameVariable: (to, context, locality) ->
    #Should validate context.selected to be a valid variable
    console.log 'renaming variable', context.selected , ' to ', to
    if (locality == 'file')
      replaceTarget = context.scopeAnalysis.ast
    else
      replaceTarget = context.getFunctionScope().block

    newAST = estraverse.replace replaceTarget, enter:(node) ->
      if node.type == 'Identifier' && node.name == context.selected
        node.name = to
        return node
    return escodegen.generate context.scopeAnalysis.ast, comment: true

  filterGlobals: (references) ->
    references
      .filter (reference) ->
        !allGlobals.has(reference.identifier.name)

  parametersForReferences: (references) ->
    names = references.map (reference) ->
      reference.identifier.name
    names.filter (name, index) ->  #Removes duplicates
      names.indexOf(name) == index


  getParentScopeNode: (analysis, position) ->
    scope = analysis.currentScope
    scope = @findScopeContaining(position, scope)
    scope = if scope.upper then scope.upper else scope
    scope.block

  findScopeContaining: (position, scope) ->
    self = this
    if scope.block.range[0] < position && position< scope.block.range[1]
      filtered = scope.childScopes.map (child) ->
        self.findScopeContaining(position, child)
      .filter (child) ->
        child != null
      answer = if filtered.length == 0  then scope else filtered[0]
    else
      answer = null

    return answer

  getInsertionBody: (analysis, position) ->
    parentScopeNode = @getParentScopeNode(analysis, position)
    switch parentScopeNode.type
      when "ExpressionStatement" then parentScopeNode.body.expression.callee.body.body #IIFE
      when "FunctionExpression" then parentScopeNode.body.body
      when "FunctionDeclaration" then parentScopeNode.body.body
      when "Program" then parentScopeNode.body #Global Scope
    #WrappingNode, FunctionNode, ProgramNode

  extractFunction: (name, context) ->
    #TODO Handle Parse Errors via catch the selected text must be a valid snippet
    analysis = @getAnalysis(context.selected)
    functionScope = context.getFunctionScope()
    localReferences = analysis.currentScope.references
      .filter (reference) ->
        functionScope.variables.some (variable) ->
          variable.name == reference.identifier.name
    localReferences = @filterGlobals localReferences
    parameters = @parametersForReferences(localReferences).join(', ')
    #Check if we are dealing with an expression or with a set of statements
    if @isSinlgeLineExpression(analysis.ast)
      semicolon = if context.selected.indexOf ';' == -1 then '' else ';'
      source = "function #{name}(#{parameters}){\n return #{context.selected}#{semicolon}\n}"
      call = "#{name}(#{parameters})"
    else
      source = "function #{name}(#{parameters}){\n#{context.selected}\n}"
      call = "#{name}(#{parameters});"

    generatedAst = @parse(source)
    analysis = @getAnalysis(context.replaceSelectionWith(call))
    body = @getInsertionBody analysis, context.positionStart
    body.push(generatedAst)
    escodegen.generate analysis.ast, comment: true

  isSingleLineExpression: (ast) ->
    ast.body.length == 1 && ast.body[0].type == 'ExpressionStatement'

  inlineFunction: (context) ->
    #TODO VAlidate if funciton is single expression or multiple to inline.
    self = this
    functionScope = context.getFunctionScope()
    inline = escodegen.generate functionScope.block.body, comment: true, format: semicolons: false
    parameters = functionScope.block.params.map (varNode ) ->
      varNode.name
    inline = inline.slice 1, (inline.length - 1) #Remove brackets
    inline = inline.replace('return', '') #Remove return
    inlineAst = self.parse(inline)
    if @isSingleLineExpression(inlineAst)
      inline = inline.replace(';', '') #Remove return
    fileAst = context.scopeAnalysis.ast
    estraverse.replace fileAst, fallback: 'iteration',  enter:(node) ->
      if node.type == 'CallExpression' && node.callee.name == functionScope.block.id.name
        inlineAst = self.parse(inline)
        #Replace parameters with passed arguments
        estraverse.replace inlineAst, enter:(inlineNode) ->
          if inlineNode.type == 'Identifier' && ((parameters.indexOf inlineNode.name) != -1)
            node.arguments[parameters.indexOf inlineNode.name]
          else
            inlineNode
        inlineAst
      else
        node
    return escodegen.generate context.scopeAnalysis.ast, comment: true, format: semicolons: true


module.exports = new RefactoringEngine
