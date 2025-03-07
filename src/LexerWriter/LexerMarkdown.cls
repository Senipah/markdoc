VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "LexerMarkdown"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'-------------------------------------------------------------------------------
'   Class: LexerMarkdown
'   Parses and tokenises markdown.
'-------------------------------------------------------------------------------

Private mBlockStack As List
Private mLinkReference As Object
Private mAttachedDocument As Document

Private mFencedCodeFence As String
Private mFencedCodeIndent As Long
Private mIndentLevel As Long
Private mPreviousLine As String
Private mLine As String


'Properties
'-------------------------------------------------------------------------------
Public Property Get BlockStack() As List
    Set BlockStack = mBlockStack
End Property

Public Property Set AttachedDocument(var As Document)
    Set mAttachedDocument = var
End Property

Public Property Get AttachedDocument() As Document
    If mAttachedDocument Is Nothing Then
        Set mAttachedDocument = Application.Documents.Add
    End If
    Set AttachedDocument = mAttachedDocument
End Property


' Constructor
'-------------------------------------------------------------------------------
Private Sub Class_Initialize()
'   Initialise the block stack.
    Set mBlockStack = New List
    mBlockStack.SetStandardStyle

'   Initialise the links reference dictionary.
    Set mLinkReference = CreateObject("Scripting.Dictionary")

'   Push the document level block onto the stack.
    mBlockStack.Push New BlockContainer
    OpenChildBlock
End Sub


' Methods
'-------------------------------------------------------------------------------
Public Sub ParseMarkdown(textStream As IFileReader)
'   Phase 1:
'   Parse the text stream into blocks.
    Do While Not textStream.EOF
        mLine = textStream.ReadNextLine
        ParseLineType mLine
        mPreviousLine = mLine
    Loop
'   Convert last block to Paragraph if it is unknown.
    CThisBlockContainerToParagraph
End Sub

Public Sub ParseTree()
'   Phase 2:
'   Parse the leaf blocks.
    Dim docLevelBlock As BlockContainer
    Set docLevelBlock = mBlockStack.Items(mBlockStack.Count)
    ParseBlockTree docLevelBlock
End Sub

Public Sub WriteDocument()
'   Writes the parsed markdown to a new document.

'   Reference the markdown block tree
    Dim mkdwn As BlockContainer
    Set mkdwn = mBlockStack.Items(mBlockStack.Count)

'   Exit if there's no tree.
    If Not BlockTreeHasContent(mkdwn) Then
        Throw = Errs.LexerWarnNothingToWrite
        Exit Sub
    End If

'   Write to and style the document.
    mkdwn.WriteContent AttachedDocument
    mkdwn.StyleContent AttachedDocument
End Sub


' Helpers: Blocks
'-------------------------------------------------------------------------------
Private Sub CloseBlock()
'   Pops the current block and discards the reference
'
    CThisBlockContainerToParagraph

    Dim discard As IBlock
    Set discard = mBlockStack.Pop

    Logger.Log "Closed block (" & mBlockStack.Count & ")"
End Sub

Private Sub OpenChildBlock()
'   Create a new block container as a child of the current block.
    Dim newChildBlock As New BlockContainer
    Dim currentBlock As IBlockContainer

'   This will raise an error if we do not have a container block
    Set currentBlock = ThisBlock

'   Associate with current, push to stack
    currentBlock.Children.Push newChildBlock
    mBlockStack.Push newChildBlock

    Logger.Log "Opened child block (" & mBlockStack.Count & ")"
End Sub

Private Sub OpenSiblingBlock()
'   Close the current block and open a child of the same parent.
'
    CloseBlock
    Dim indlev As Long
    indlev = ThisBlock.IndentationLevel

    OpenChildBlock
    ThisBlock.IndentationLevel = indlev
End Sub

Private Sub LazyOpenSiblingBlock()
'   Opens a new sibling if the current block has content.
'   Otherwise, does nothing.
'
    CThisBlockContainerToParagraph
    If ThisContentBlock.ContentText = vbNullString Then Exit Sub
    OpenSiblingBlock
End Sub

Private Function ThisBlock() As IBlock
'   Returns the current block container.
'
'   Returns:
'       The current block.
'
    Dim tb As Variant
    Set tb = mBlockStack.Peek
    If TypeOf tb Is IBlock Then
        Set ThisBlock = tb
    End If
End Function

Private Sub CThisBlockLeaf(castToBlock As IBlockLeaf)
'   Casts ThisBlock to another block type.
'   This helper is a shortcut to casting ThisBlock as it cannot be done
'   directly. The reference is lost so the block must be popped and pushed.
'
'   Args:
'       castToBlock: The target block to cast to.
'
    Dim block As IBlock
    Set block = mBlockStack.Pop
    Utils.CBlockLeaf block, castToBlock, ThisBlock
    mBlockStack.Push block
End Sub

Private Function ThisContentBlock() As IBlockContent
'   Gets the current block container as an IBlockContent
'   which enables use of the interface methods.
'
'   Returns:
'       The current block.
'
    Set ThisContentBlock = ThisBlock
End Function

Private Sub CThisBlockContainerToParagraph()
'   Casts BlockContainer ThisBlock to a paragraph.
'   No effect if not BlockContainer.
'
    If Not TypeOf ThisBlock Is BlockContainer Then Exit Sub

    Dim block As IBlock
    Set block = mBlockStack.Pop

    Dim blockContent As BlockContainer
    Set blockContent = block

    If Not blockContent.ContentText = vbNullString Then
        Utils.CBlockLeaf block, New BlockLeafParagraph, ThisBlock
    End If
    mBlockStack.Push block
End Sub

Private Sub SetThisBlockContent()
'   Sets the content for the current block.
'
'   If it is not already a leaf of some sort, it is cast to a paragraph.
'   This is based on the assumption that all other kinds will have been
'   detected and cast by this point.

    Dim block As IBlock
    Set block = ThisBlock
    
    If TypeOf block Is IBlockContainer Then
'       Cast to paragraph.
        Utils.CBlockLeaf block, New BlockLeafParagraph, ThisBlock
    Else
        Throw = Errs.BlockTypeMismatch
    End If
End Sub

Private Function BlockTreeHasContent(currentBlock As IBlock) As Boolean
'   Checks whether anything exists to write.
'
'   Args:
'       currentBlock: The current block to test.
'
'   Returns:
'       True if something exists to write to a document.

    Dim contentBlock As IBlockContent
    Dim containerBlock As IBlockContainer
    Dim childBlock As IBlock

'   Test the current block.
    If TypeOf currentBlock Is IBlockContent Then
        Set contentBlock = currentBlock
        If Not contentBlock.ContentText = vbNullString Then
            BlockTreeHasContent = True
            Exit Function
        End If
    End If

'   Test children.
    If TypeOf currentBlock Is IBlockContainer Then
        Set containerBlock = currentBlock
        For Each childBlock In containerBlock.Children
            If BlockTreeHasContent(childBlock) Then
                BlockTreeHasContent = True
                Exit Function
            End If
        Next childBlock
    End If
End Function


' Helpers: Parser
'-------------------------------------------------------------------------------
Private Sub ParseLineType(line As String)
'   Prepares the line and calls ParseLineTypeAction
'   TODO: Figure out a way to modularise this so it isn't n level ifs.
'
'   Args:
'       line: The raw line as it is read from the source.

    Dim cleanLine As String
    Dim unindentLine As String
    Dim thisIndentLevel As Long

'   Clean, get indentation, and unindent line.
    cleanLine = Utils.CleanString(line)

    If Trim(cleanLine) = vbNullString Then
        thisIndentLevel = ThisBlock.IndentationLevel
    Else
        unindentLine = Utils.unindentLine(cleanLine, ThisBlock.IndentationLevel)
        thisIndentLevel = Utils.GetIndentationLevel(unindentLine)
    End If

    ParseLineTypeAction cleanLine, unindentLine, thisIndentLevel
End Sub

Private Sub ParseLineTypeAction( _
    lineCleaned As String, _
    lineUnindented As String, _
    indentLevel As Long)
'   Performs the parse action depending on current state.
'   This sub can call itself recursively if more than one action relevant.
'
'   Args:
'       lineCleaned: The cleaned version of the original line.
'       lineUnindented: The unindented version of the cleaned line.
'       indentLevel: The indent level in spaces of the line.
'
'   Raises:
'

'   An indentation level reduction will always kick us out of the block.
'   Blank lines are considered to have the same indentation as previous line.
    If indentLevel < ThisBlock.IndentationLevel Then
        CloseBlock
        ParseLineTypeAction lineCleaned, lineUnindented, indentLevel
    End If
    
    Dim matches As Object
    Dim block As IBlock
    Dim hdg As BlockLeafHeading

    Select Case True
'       Parsing from inside fenced code block.
        Case Is = IsInFencededCodeLeaf
'           Check for a close fence string.
            If Parser.IsCodeBlockFence(lineCleaned, mFencedCodeFence) Then
                CloseBlock
'           Nothing else pulls us out of this block type.
            Else
                ThisContentBlock.ContentText = lineUnindented
            End If

'       Parsing from inside indented code block.
        Case Is = IsInIndentedCodeLeaf
            ThisContentBlock.ContentText = lineUnindented

'       Parsing from inside a paragraph.
        Case Is = IsInParagraphLeaf
            Select Case True
'               Blank lines break the paragraph.
                Case Is = lineUnindented = vbNullString
                    OpenSiblingBlock
                    CThisBlockLeaf New BlockLeafBlankLine
'               A code fence breaks the paragraph.
                Case Is = Parser.IsCodeBlockFence( _
                    lineUnindented, mFencedCodeFence)
                    OpenSiblingBlock
                    CThisBlockLeaf New BlockLeafFencedCode
'               A heading breaks the paragraph.
                Case Is = Parser.IsHeading(lineUnindented, matches)
                    CloseBlock
                    CThisBlockLeaf New BlockLeafHeading

                    Set hdg = ThisBlock
                    hdg.ContentText = matches(0).Submatches(1)
                    hdg.HeadingLevel = Parser.ParseHeadingLevel( _
                        matches(0).Submatches(0))
'               A new list breaks the paragraph.
                Case Is = Parser.IsListItem(lineUnindented, matches)
                    Throw = Errs.NotImplementedException
'               Nothing else pulls us out of this block type.
                Case Else
                    ThisContentBlock.ContentText = lineUnindented
            End Select

'       Parsing from inside a block of blank lines.
        Case Is = IsInBlankLineLeaf
'           Non-blank line should open an unknown sibling block for parsing.
            If Not lineUnindented = vbNullString Then
                OpenSiblingBlock
                ParseLineTypeAction lineCleaned, lineUnindented, indentLevel
            End If
        
'       Parse from inside an empty block.
        Case ThisContentBlock.ContentText = vbNullString
            Dim newBlockType As BlockType
            newBlockType = Parser.ParseUnknownBlockLine( _
                lineUnindented, matches)

            Select Case True
                Case Is = Parser.IsCodeBlockFence( _
                    lineUnindented, mFencedCodeFence)
                    CThisBlockLeaf New BlockLeafFencedCode
                Case Else
                    Select Case newBlockType
                        Case Is = BlockType.Heading
                            LazyOpenSiblingBlock
                            CThisBlockLeaf New BlockLeafHeading
                            Set hdg = ThisBlock
                            hdg.ContentText = matches(0).Submatches(1)
                            hdg.HeadingLevel = Parser.ParseHeadingLevel( _
                                matches(0).Submatches(0))
                            OpenSiblingBlock
                        Case Is = BlockType.Paragraph
                            ThisContentBlock.ContentText = lineUnindented
                    End Select
            End Select

'       Parse from an unknown block that has content.
        Case Else
            Select Case True
'               Content becoming blank line is a paragraph.
                Case Is = lineUnindented = vbNullString
                    LazyOpenSiblingBlock
                    CThisBlockLeaf New BlockLeafBlankLine
'               Content becoming code block fence is a paragraph.
                Case Is = Parser.IsCodeBlockFence( _
                    lineUnindented, mFencedCodeFence)
                    LazyOpenSiblingBlock
                    CThisBlockLeaf New BlockLeafFencedCode
'               Content becoming a heading is a paragraph.
                Case Is = Parser.IsHeading(lineUnindented, matches)
                    LazyOpenSiblingBlock
                    CThisBlockLeaf New BlockLeafHeading
                    Set hdg = ThisBlock

                    hdg.ContentText = matches(0).Submatches(1)
                    hdg.HeadingLevel = Parser.ParseHeadingLevel( _
                        matches(0).Submatches(0))
'               Content becoming a new list is a paragraph.
                Case Is = Parser.IsListItem(lineUnindented, matches)
                    LazyOpenSiblingBlock
                    Throw = Errs.NotImplementedException
                Case Else
                    ThisContentBlock.ContentText = lineUnindented
            End Select
    End Select
End Sub

Private Sub ParseBlockTree(block As IBlock)
'   Parses the block content if it's a leaf and calls this method
'   recursively on its children. You should only need to pass the
'   document level block to this sub.
'
'   Args:
'       block: The block with content or children to be parsed.
'
'   Raises:
'       BlockTypeMismatch if passed an object that is neither
'       IBlockContainer nor IBlockContent.

    If TypeOf block Is IBlockContainer Then
        Dim container As IBlockContainer
        Dim child As IBlock

        Set container = block
        For Each child In container.Children
            ParseBlockTree child
        Next child

    ElseIf TypeOf block Is IBlockContent Then
        Dim content As IBlockContent
        Set content = block
        Logger.Log "Parsing... " & content.ContentText
    
    Else
        Throw = Errs.BlockTypeMismatch
    End If

End Sub


' Helpers: Parser State
'-------------------------------------------------------------------------------
Private Function IsInFencededCodeLeaf() As Boolean
'   Parser state flag is in fenced code.
'
'   Returns:
'       True if the current block is a BlockLeafParagraph
    IsInFencededCodeLeaf = TypeOf ThisBlock Is BlockLeafFencedCode
End Function

Private Function IsInIndentedCodeLeaf() As Boolean
'   Parser state flag is in indented code.
'
'   Returns:
'       True if the current code block is an indented code block.
    IsInIndentedCodeLeaf = TypeOf ThisBlock Is BlockLeafIndentedCode
End Function

Private Function IsInParagraphLeaf() As Boolean
'   Parser state flag is in paragraph.
'
'   Returns:
'       True if the current block is a BlockLeafParagraph

    IsInParagraphLeaf = TypeOf ThisBlock Is BlockLeafParagraph
End Function

Private Function IsInBlankLineLeaf() As Boolean
'   Parser state flag is in blank lines.
'
'   Returns:
'       True if the current block is a BlockLeafParagraph

    IsInBlankLineLeaf = TypeOf ThisBlock Is BlockLeafBlankLine
End Function
