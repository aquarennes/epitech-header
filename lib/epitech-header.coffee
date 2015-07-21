{CompositeDisposable} = require 'atom'
path = require 'path'
fullname = require 'fullname'
username = require 'username'
Template = require './template'

module.exports = EpitechHeader =
  insertTemplateStr: null
  updateTemplateStr: null
  subscriptions: null

  activate: (state) ->
    atom.workspace.observeTextEditors (editor) =>
      editor.getBuffer().onWillSave => @update(editor.getBuffer())

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable
    # Register command that toggles this view

    @insertTemplateStr = """
    /*
    ** {{filename}} for {{project}} in {{directory}}
    **
    ** Made by {{author}}
    ** Login   <{{author_username}}@epitech.net>
    **
    ** Started on  {{start_date}} {{start_time}} {{author}}
    ** Last update {{start_date}} {{start_time}} {{author}}
    */\n
    """

    @updateTemplateStr = """** Last update {{date}} {{time}} {{author}}"""

    @subscriptions.add atom.commands.add 'atom-workspace', 'epitech-header:insert': => @insert()

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->

  getFileProject: (file) ->
    unless file?
      return 'project'
    filePath = file.path
    project = atom.project.relativizePath(filePath)
    unless project?
      return 'project'
    if project[0] is null
      return 'project'
    paths = project[0].split('/')
    return paths.pop()

  insert: (event) ->
    fullname((err, name) =>
      if err
        return
      template = new Template(@insertTemplateStr)
      editor = atom.workspace.getActiveTextEditor()
      unless editor?
        return
      coordinates = editor.getCursorBufferPosition()
      editor.moveToTop()
      editor.moveToBeginningOfLine()
      buffer = atom.workspace.getActivePaneItem().buffer
      project = @getFileProject buffer.file
      date = new Date()
      curdate = date.toDateString().replace(date.getFullYear(), '').trim()
      curtime = date.toLocaleTimeString 'fr-FR', hour12: false
      template.replace '{{filename}}', editor.getTitle()
      template.replace '{{project}}', project
      template.replace '{{directory}}', path.dirname(editor.getPath())
      template.replace '{{author}}', name
      template.replace '{{author_username}}', username.sync()
      template.replace '{{start_date}}', curdate
      template.replace '{{start_time}}', curtime
      editor.insertText template.getTemplate()
      editor.setSelectedBufferRange [
        [1, 8 + editor.getTitle().length],
        [1, 8 + editor.getTitle().length + project.length]
      ]
    )

  update: (textBuffer) ->
    content = textBuffer.getLines()
    if content.length < 8
      return
    unless content[0].startsWith '/*'
      return
    for i in [1..7]
      unless content[i].startsWith '**'
        return
    unless content[8].startsWith '*/'
      return
    lineLength = content[7].length
    fullname (err, name) =>
      if err
        return
      date = new Date()
      curdate = date.toDateString().replace(date.getFullYear(), '').trim()
      curtime = date.toLocaleTimeString 'fr-FR', hour12: false
      template = new Template @updateTemplateStr
      template.replace '{{date}}', curdate
      template.replace '{{time}}', curtime
      template.replace '{{author}}', name or username.sync()
      textBuffer.setTextInRange [[7, 0], [7, lineLength]], template.getTemplate()
