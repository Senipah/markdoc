VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "IFileReader"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'-------------------------------------------------------------------------------
'   Interface: IFileReader
'   An interface that describes base file reading methods.
'   This interface exists so different text objects can be swapped out,
'   e.g. file, direct text, or http get.
'-------------------------------------------------------------------------------


Public Property Get EOF() As Boolean
'   Returns True if the entire contents has been read.
    Throw = Errs.InterfaceUsedAsObject
End Property

Public Function ReadNextLine() As String
'   Returns the next line to be read and advances the pointer.
    Throw = Errs.InterfaceUsedAsObject
End Function

Public Function PeekNextLine() As String
'   Returns the next line to be read without advancing the pointer.
    Throw = Errs.InterfaceUsedAsObject
End Function

Public Sub OpenStream(fileOrTextReference As String)
'   Sets a reference to the text stream.
    Throw = Errs.InterfaceUsedAsObject
End Sub
