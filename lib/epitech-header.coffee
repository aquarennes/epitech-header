{CompositeDisposable} = require 'atom'
path = require 'path'
fullname = require 'fullname'
username = require 'username'

module.exports = EpitechHeader =
  epitechHeaderView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    atom.workspace.observeTextEditors (editor) =>
      editor.getBuffer().onWillSave => @update(editor.getBuffer())

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable
    # Register command that toggles this view

    @subscriptions.add atom.commands.add 'atom-workspace', 'epitech-header:insert': => @insert()

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->

  insert: (event) ->
    fullname((err, name) ->
      if err
        return
      template = """
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
      editor = atom.workspace.getActiveTextEditor()
      coordinates = editor.getCursorBufferPosition()
      editor.moveToTop()
      editor.moveToBeginningOfLine()
      buffer = atom.workspace.getActivePaneItem().buffer
      filePath = buffer.file.path
      project = atom.project.relativizePath(filePath)
      if project?
        paths = project[0].split('/')
        project = paths.pop()
      else
        project = 'project'
      date = new Date()
      curdate = date.toDateString().replace(date.getFullYear(), '').trim()
      curtime = date.toLocaleTimeString('fr-FR', {hour12: false})
      template = template.replace('{{filename}}', editor.getTitle())
      template = template.replace('{{project}}', project)
      template = template.replace('{{directory}}', path.dirname(editor.getPath()))
      template = template.replace('{{author}}', name)
      template = template.replace('{{author}}', name)
      template = template.replace('{{author}}', name)
      template = template.replace('{{author_username}}', username.sync())
      template = template.replace('{{start_date}}', curdate)
      template = template.replace('{{start_date}}', curdate)
      template = template.replace('{{start_time}}', curtime)
      template = template.replace('{{start_time}}', curtime)
      editor.insertText(template)
      editor.setSelectedBufferRange([[1, 8 + editor.getTitle().length], [1, 8 + editor.getTitle().length + project.length]])
    )

  update: (textBuffer) ->
    content = textBuffer.getLines()
    if content.length < 8
      return
    unless content[0].startsWith('/*')
      return
    for i in [1..7]
      unless content[i].startsWith('**')
        return
    unless content[8].startsWith('*/')
      return
    lineLength = content[7].length
    fullname (err, name) ->
      if err
        return
      date = new Date()
      curdate = date.toDateString().replace(date.getFullYear(), '').trim()
      curtime = date.toLocaleTimeString('fr-FR', {hour12: false})
      template = '** Last update {{date}} {{time}} {{author}}'
      template = template.replace('{{date}}', curdate)
      template = template.replace('{{time}}', curtime)
      template = template.replace('{{author}}', name)
      textBuffer.setTextInRange([[7, 0], [7, lineLength]], template)
