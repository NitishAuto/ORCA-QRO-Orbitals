Attribute VB_Name = "MOSlideGenerator"
Sub Make_MO_Slide_FINAL()
    ' -------------------------------------------------------------------------
    ' Macro Name: Make_MO_Slide_FINAL
    ' Description: This macro asks the user for a folder containing Molecular 
    '              Orbital (MO) images and a 'gopal.txt' file. It parses the 
    '              text file for MO data, sorts the images numerically, and 
    '              automatically generates a PowerPoint presentation with 
    '              the images and their corresponding text arranged in a grid.
    ' -------------------------------------------------------------------------

    Dim imgFolder As String, gopalFile As String
    
    ' ===== FOLDER PICKER =====
    ' Prompt the user to select the directory containing images and gopal.txt
    Dim fd As FileDialog
    Set fd = Application.FileDialog(msoFileDialogFolderPicker)
    fd.Title = "Select the folder containing your MO images and gopal.txt"
    fd.ButtonName = "Select Folder"
    
    If fd.Show = -1 Then
        ' User selected a folder
        imgFolder = fd.SelectedItems(1) & "\"
    Else
        ' User clicked Cancel
        MsgBox "No folder selected. Macro canceled.", vbExclamation
        Exit Sub
    End If
    
    gopalFile = imgFolder & "gopal.txt"
    
    ' Check if gopal.txt actually exists in the selected folder
    If Dir(gopalFile) = "" Then
        MsgBox "Could not find 'gopal.txt' in the selected folder. Please check the folder and try again.", vbCritical
        Exit Sub
    End If

    ' ===== GRID CONFIGURATION =====
    Dim imgW As Single, imgH As Single
    imgW = 2 * 72 ' Width of images (in points, 72 points = 1 inch)
    imgH = 2 * 72 ' Height of images
    Dim cols As Integer
    cols = 4      ' Number of columns per slide

    ' ===== READ GOPAL.TXT =====
    Dim txt As String, fileNum As Integer
    fileNum = FreeFile
    Open gopalFile For Binary As #fileNum
    txt = Space$(LOF(fileNum))
    Get #fileNum, , txt
    Close #fileNum

    ' Normalize Line Endings & Fix Unicode characters
    txt = Replace(txt, vbCrLf, vbLf)
    txt = Replace(txt, vbCr, vbLf)
    txt = Replace(txt, "Â²", "²")
    txt = Replace(txt, "Ã‚", "")
    
    Dim lines() As String
    lines = Split(txt, vbLf)

    ' ===== PARSE DATA =====
    ' Array to hold MO data: (index, 0=MO number, 1=Image Path, 2=Full Text)
    Dim moData() As Variant
    ReDim moData(0 To UBound(lines), 0 To 2)
    Dim validCount As Integer
    validCount = 0

    Dim i As Integer, moParts() As String
    Dim moNum As Integer, moNumStr As String, imgPath As String
    Dim cleanLine As String, contribLine As String
    Dim fullText As String, tempStr As String

    For i = 0 To UBound(lines)
        cleanLine = Trim(lines(i))

        If Left(cleanLine, 3) = "MO " Then
            tempStr = cleanLine
            ' Normalize multiple spaces to a single space
            Do While InStr(tempStr, "  ") > 0
                tempStr = Replace(tempStr, "  ", " ")
            Loop
            moParts = Split(tempStr, " ")
            
            If UBound(moParts) >= 1 Then
                moNumStr = moParts(1)
            Else
                GoTo SkipBlock
            End If

            ' Ensure the parsed MO number is valid
            If Not IsNumeric(moNumStr) Then GoTo SkipBlock
            
            moNum = CInt(moNumStr)
            imgPath = imgFolder & "mo" & moNumStr & ".png"
            
            ' Check if the corresponding image exists
            If Dir(imgPath) <> "" Then
                fullText = "(" & moNumStr & ")" & vbCrLf & cleanLine

                ' Check the next line for contribution details
                If i + 1 <= UBound(lines) Then
                    contribLine = Trim(lines(i + 1))
                    If Left(contribLine, 3) <> "MO " And contribLine <> "" Then
                        fullText = fullText & vbCrLf & contribLine
                        i = i + 1 ' Skip the contribution line since it's processed
                    End If
                End If

                ' Store valid MO into our array
                moData(validCount, 0) = moNum
                moData(validCount, 1) = imgPath
                moData(validCount, 2) = fullText
                validCount = validCount + 1
            End If
        End If
SkipBlock:
    Next i

    If validCount = 0 Then
        MsgBox "No valid MO images found in that folder.", vbExclamation
        Exit Sub
    End If

    ' ===== SORT DATA NUMBER-WISE (Bubble Sort) =====
    Dim j As Integer, k As Integer
    Dim tempNum As Integer, tempImg As String, tempTxt As String
    For j = 0 To validCount - 2
        For k = j + 1 To validCount - 1
            If moData(j, 0) > moData(k, 0) Then
                ' Swap items
                tempNum = moData(j, 0): tempImg = moData(j, 1): tempTxt = moData(j, 2)
                moData(j, 0) = moData(k, 0): moData(j, 1) = moData(k, 1): moData(j, 2) = moData(k, 2)
                moData(k, 0) = tempNum: moData(k, 1) = tempImg: moData(k, 2) = tempTxt
            End If
        Next k
    Next j

    ' ===== GENERATE POWERPOINT SLIDES =====
    Dim sld As Slide
    ' Add the first blank slide
    Set sld = ActivePresentation.Slides.Add(ActivePresentation.Slides.Count + 1, ppLayoutBlank)

    Dim leftPos As Single, topPos As Single
    leftPos = 40
    topPos = 40
    Dim colCount As Integer
    colCount = 0
    Dim shpText As Shape

    For j = 0 To validCount - 1
        ' 1. Insert Image
        sld.Shapes.AddPicture moData(j, 1), msoFalse, msoTrue, leftPos, topPos, imgW, imgH

        ' 2. Insert Text Box
        Set shpText = sld.Shapes.AddTextbox(msoTextOrientationHorizontal, leftPos - 10, topPos + imgH + 5, imgW + 20, 20)
        With shpText.TextFrame
            .WordWrap = msoTrue
            .AutoSize = ppAutoSizeShapeToFitText
            With .TextRange
                .Text = moData(j, 2)
                .Font.Name = "Verdana"
                .Font.Size = 9
                .Font.Bold = False
                .ParagraphFormat.Alignment = ppAlignCenter
            End With
        End With

        ' 3. Calculate position for the next item
        leftPos = leftPos + imgW + 20
        colCount = colCount + 1

        ' Check if a new row is needed
        If colCount = cols Then
            colCount = 0
            leftPos = 40
            topPos = topPos + imgH + shpText.Height + 15

            ' Check if a new slide is needed based on available height
            If topPos + imgH + 60 > ActivePresentation.PageSetup.SlideHeight Then
                Set sld = ActivePresentation.Slides.Add(ActivePresentation.Slides.Count + 1, ppLayoutBlank)
                topPos = 40
            End If
        End If
    Next j

    MsgBox "Automation Complete! Sorted MO Slide Generated.", vbInformation

End Sub
