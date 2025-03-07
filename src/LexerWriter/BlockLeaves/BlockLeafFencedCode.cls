VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "BlockLeafFencedCode"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Implements IBlock
Implements IBlockLeaf
Implements IBlockContent

'-------------------------------------------------------------------------------
'   Class: BlockLeafFencedCode
'
'   A leaf block paragraph is a block that has content and styling information.
'   Fenced code blocks do not contain children or siblings.
'-------------------------------------------------------------------------------


' Private Backing Store
'-------------------------------------------------------------------------------
Private mContentText As String
Private mIndentLevel As Long
Private mInlineContent As InlineContent


' Properties
'-------------------------------------------------------------------------------
Public Property Let ContentText(var As String)
    If Len(mContentText) > 0 Then mContentText = mContentText & vbNewLine
    mContentText = mContentText & var
End Property

Public Property Get ContentText() As String
    ContentText = mContentText
End Property

Public Property Let IndentationLevel(var As Long)
    mIndentLevel = var
End Property

Public Property Get IndentationLevel() As Long
    IndentationLevel = mIndentLevel
End Property


' Methods
'-------------------------------------------------------------------------------
Public Sub WriteContent(toDoc As Document)
'   This method MUST be called before StyleContent.
    Logger.Log "Writing " & TypeName(Me) & ": " & mContentText
    Set mInlineContent = New InlineContent
    mInlineContent.Text = mContentText
    With mInlineContent
        Set .Range = toDoc.Range(Len(toDoc.content) - 1)
        .Range.Text = .Text
    End With
End Sub

Public Sub StyleContent(styleDoc As Document)
'   This method MUST be called after WriteContent.
    Dim styleName As String
    styleName = Enums.BlockTypeToStyleName(BlockType.FencedCode)
    mInlineContent.Range.Style = DocumentShortcuts.GetStyle(styleName)
End Sub


' Interface Implementation
'-------------------------------------------------------------------------------
Public Property Let IBlock_IndentationLevel(var As Long)
    IndentationLevel = var
End Property

Public Property Get IBlock_IndentationLevel() As Long
    IBlock_IndentationLevel = IndentationLevel
End Property

Public Sub IBlock_WriteContent(toDoc As Document)
    WriteContent toDoc
End Sub

Public Sub IBlock_StyleContent(styleDoc As Document)
    StyleContent styleDoc
End Sub

Public Property Let IBlockLeaf_ContentText(var As String)
    ContentText = var
End Property

Public Property Get IBlockLeaf_ContentText() As String
    IBlockLeaf_ContentText = ContentText
End Property

Public Sub IBlockLeaf_WriteContent(toDoc As Document)
    WriteContent toDoc
End Sub

Public Sub IBlockLeaf_StyleContent(styleDoc As Document)
    StyleContent styleDoc
End Sub

Public Property Let IBlockContent_ContentText(var As String)
    ContentText = var
End Property

Public Property Get IBlockContent_ContentText() As String
    IBlockContent_ContentText = ContentText
End Property
