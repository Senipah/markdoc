VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "BlockLeafHeading"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Implements IBlock
Implements IBlockLeaf
Implements IBlockContent

'-------------------------------------------------------------------------------
'   Class: BlockLeafHeading
'   A block that represents a title or heading of any level.
'   ATX Headings:
'       - Regex: ^\s{0,3}(#{1,6})\s+(.*?)\s*(?:#*\s*)$
'       - The heading content is capture group 2.
'       - Content parsed as inline text, similar to a paragraph.
'       - The heading level is derived from capture group 1.
'       - Level is count of # minus one, 0 is title, > 0 is heading.
'-------------------------------------------------------------------------------

' Private Backing Store
'-------------------------------------------------------------------------------
Private mMyParagraph As Paragraph
Private mContentText As String
Private mIndentLevel As Long
Private mInlineConts As List
Private mHeadngLevel As Long

' Properties
'-------------------------------------------------------------------------------
Public Property Let ContentText(var As String)
    mContentText = var
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

Public Property Let HeadingLevel(var As Long)
    If Utils.Between(var, 0, 6) Then
        mHeadngLevel = var
    End If
End Property

Public Property Get HeadingLevel() As Long
    HeadingLevel = mHeadngLevel
End Property


' Methods
'-------------------------------------------------------------------------------
Public Sub WriteContent(toDoc As Document)
'   This method MUST be called before StyleContent.
    Logger.Log "Writing " & TypeName(Me) & ": " & mContentText
    If mContentText = vbNullString Then Exit Sub

    With toDoc
'       Initialise new paragraph
        If Len(.content) > 1 Then
            If Not Utils.EndsWithNewLine(.content) Then
                .content.InsertAfter Text:=vbNewLine
            End If
            .Paragraphs.Add
        End If

'       Save the working paragraph for later styling.
        Set mMyParagraph = .Paragraphs(.Paragraphs.Count)
    End With

    Dim inlineCont As InlineContent
'   Set ranges and write content to new paragraph.
'   >>>>
'   For now, directly set the content as inline content.
'   This code should be removed as functionality developed.
    Set mInlineConts = New List
    Set inlineCont = New InlineContent
    inlineCont.Text = mContentText
    mInlineConts.Push inlineCont
'   <<<<
    For Each inlineCont In mInlineConts
        With inlineCont
            Set .Range = toDoc.Range(Len(toDoc.content) - 1)
            .Range.Text = .Text
        End With
    Next inlineCont
End Sub

Public Sub StyleContent(styleDoc As Document)
'   This method MUST be called after WriteContent.
    Dim styleName As String
    styleName = Enums.BlockTypeToStyleName(BlockType.Heading, HeadingLevel) 

    Dim inlineCont As InlineContent
    Set inlineCont = mInlineConts(1)
    inlineCont.Range.Style = DocumentShortcuts.GetStyle(styleName)

'   TODO: Loop over the inline sections setting as required.
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
