Attribute VB_Name = "test_md"
Option Explicit

Const GITHUB As String = "https://raw.githubusercontent.com/SSlinky/markdoc/master/tests/"


Sub test_RunMarkDoc()
    DocumentShortcuts.Attach ThisDocument

    Dim lexer As LexerMarkdown
    Dim stream As IIo
    
    Logger.LoggingLevel = Information
    Throw.ThrowLevel = NoLevel

    Set lexer = New LexerMarkdown
    Set stream = New IoFileReader

    stream.OpenStream ActiveDocument.Path & "\tests\test_md.md"
    lexer.ParseMarkdown stream
    Set lexer.AttachedDocument = ThisDocument
    lexer.WriteDocument
End Sub

Sub test_RunMarkDoc_FromHttp()
    DocumentShortcuts.Attach ThisDocument

    Dim lexer As LexerMarkdown
    Dim stream As IFileReader

    Logger.LoggingLevel = Information
    Throw.ThrowLevel = NoLevel

    Set lexer = New LexerMarkdown
    Set stream = New HttpFileReader

    stream.OpenStream GITHUB & "test_md.md"
    lexer.ParseMarkdown stream
    Set lexer.AttachedDocument = ThisDocument
    lexer.WriteDocument
End Sub

Sub test_EmptyDoc()
    Dim stream1 As IFileReader
    Dim stream2 As IFileReader

    Set stream1 = New IoFileReader
    Set stream2 = New IoFileReader

    stream1.OpenStream ActiveDocument.Path & "\tests\test_empty.md"
    stream2.OpenStream ActiveDocument.Path & "\tests\test_md.md"
End Sub
