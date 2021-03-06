module Main where
import Graphics.UI.Gtk
import Graphics.UI.Gtk.Glade
import Graphics.Filters.GD
import Graphics.Filters.Util
--import Graphics.UI.Sifflet.GtkForeign
import Graphics.GD
import Data.IORef
import System.FilePath.Posix
import System.Directory -- for doesFileExist
import Effects
import HelperFunctions
import Effects_edge
main = do
  initGUI
  Just xml <- xmlNew "editor.glade"
  window <- xmlGetWidget xml castToWindow "window1" -- this is the main window
  set window [windowTitle := "Image Editor",windowDefaultWidth := 1300,windowDefaultHeight := 600]
  button1 <- xmlGetWidget xml castToButton "button1"
  button2 <- xmlGetWidget xml castToButton "button2"
  button3 <- xmlGetWidget xml castToButton "button3"
  sepiaButton <- xmlGetWidget xml castToButton "button4"
  button5 <- xmlGetWidget xml castToButton "button5"
  button6 <- xmlGetWidget xml castToButton "button6"
  colorizeButton <- xmlGetWidget xml castToButton "button7"
  invertButton <- xmlGetWidget xml castToButton "button8"
  embossButton <- xmlGetWidget xml castToButton "button9"
  meanButton <- xmlGetWidget xml castToButton "button10"
  edgeButton <- xmlGetWidget xml castToButton "button11"
  yEdgeButton <- xmlGetWidget xml castToButton "button12"
  xEdgeButton <- xmlGetWidget xml castToButton "button13"
  addText <- xmlGetWidget xml castToButton "button14"
  
  canvas <- xmlGetWidget xml castToImage "image1"
  menubox <- xmlGetWidget xml castToVBox "vbox3"
  scrolledwindow1 <- xmlGetWidget xml castToScrolledWindow "scrolledwindow1"
  
  fma <- actionNew "FMA" "File" Nothing Nothing
  ema <- actionNew "EMA" "Edit" Nothing Nothing
  hma <- actionNew "HMA" "Help" Nothing Nothing
  opna <- actionNew "OPNA" "Open"    (Just "Open Image") (Just stockOpen)
  sava <- actionNew "SAVA" "Save"    (Just "Save") (Just stockSave)
  exia <- actionNew "EXIA" "Exit"    (Just "Exit") (Just stockQuit)
  hlpa <- actionNew "HLPA" "Help"  (Just "help") (Just stockHelp)
  unda <- actionNew "UNDA" "Undo" (Just "Undo") (Just stockGotoFirst)
  zina <- actionNew "ZINA" "Zoom In" (Just "Zoom In") (Just stockZoomIn)
  zoua <- actionNew "ZOUA" "Zoom Out" (Just "Zoom Out") (Just stockZoomOut)
  rraa <- actionNew "RRAA" "Rotate Right" (Just "Rotate Right") (Just stockUndo)
  rlaa <- actionNew "RLAA" "Rotate Left" (Just "Rotate Left") (Just stockRedo)
  nexa <- actionNew "NEXA" "Next" (Just "Next") (Just stockGoForward)
  baca <- actionNew "BACA" "Back" (Just "Back") (Just stockGoBack)
  --create an action group with name AGR
  --actionGroupNew :: String -> IO ActionGroup
  agr <- actionGroupNew "AGR"
  -- add the actions to a group using actionGroupAddAction
  -- actionGroupAddAction :: ActionClass action => ActionGroup -> action -> IO ()
  -- mapM_ :: Monad m => (a -> m b) -> [a] -> m ()
  mapM_ (actionGroupAddAction agr) [fma, ema, hma]
  -- set no shortcut keys for all except exit
  mapM_ (\ act -> actionGroupAddActionWithAccel agr act Nothing) [opna,sava,hlpa,unda,zina,zoua,rraa,rlaa,nexa,baca]
  -- The shortcut keys do not work
  actionGroupAddActionWithAccel agr exia (Just "<Control>e")
  
  ui <- uiManagerNew
  uiManagerAddUiFromString ui uiDecl
  uiManagerInsertActionGroup ui agr 0
     --extract  the elements from the xml and play
  maybeMenubar <- uiManagerGetWidget ui "/ui/menubar"
  let menubar = case maybeMenubar of
        (Just x) -> x
        Nothing -> error "Cannot get menubar from string." 
  boxPackStart menubox menubar PackNatural 0
  maybeToolbar <- uiManagerGetWidget ui "/ui/toolbar"
  let toolbar = case maybeToolbar of
        (Just x) -> x
        Nothing -> error "Cannot get toolbar from string." 
  boxPackStart menubox toolbar PackNatural 0
  --actionSetSensitive cuta False
  
     --define the action handler for each action
     --right now it is same for each so using mapM_
  mapM_ prAct [fma,ema,hma,sava,hlpa,unda,zina,zoua,rraa,rlaa,baca,nexa] -- add any new button for menubar here for rendering
  
  expand <- newIORef True
  changeList <- newIORef []
  fileName <- newIORef ""
  tmpFileName <- newIORef ""
  tmpFileName1 <- newIORef "" 
  zoomAmount <- newIORef 0
  myFileList <- newIORef (FileList [] [])
  upLeft <- newIORef (0,0)
  downRight <- newIORef (0,0)
  fontFamily <- newIORef "Sans"
  fontSize <- newIORef 12.0
  textColor <- newIORef (0, 0, 0)
  textData <- newIORef ""
  textPoint <- newIORef (0, 0)
------------------------------------------------------------------------------------------
  {--
this requires fileName,tmpFilename,tmpFilename1,canvas for a function
--}
  
  onActionActivate exia $ do 
    effectList <- readIORef changeList
    case effectList of               
      [] -> do
        --(widgetDestroy window)
        
        tmpFile <- readIORef tmpFileName
        val <- doesFileExist tmpFile
        if (val==True) then removeFile tmpFile else putStrLn "No file Present"
        mainQuit
      _ -> do
         bwindow <- windowNew
         set bwindow [windowTitle := "Save the changes?", windowDefaultHeight := 100, windowDefaultWidth := 300, containerBorderWidth := 10 ]
         vb <- vBoxNew False 0
         containerAdd bwindow vb
         hb <- hBoxNew False 0
         boxPackStart vb hb PackGrow 0
         myok <- buttonNewWithLabel "OK"
         boxPackStart hb myok PackGrow 0
         mycancel <- buttonNewWithLabel "Cancel"
         boxPackStart hb mycancel PackGrow 0
         onClicked myok $ do
           putStrLn "HELLLLLLO"
           tmpFile1 <- readIORef tmpFileName
           originalFileName <- readIORef fileName
           img <- loadImgFile tmpFile1
           saveImgFile (-1) originalFileName img
           widgetDestroy bwindow	
           --widgetDestroy window
           val <- doesFileExist tmpFile1
           if (val==True) then removeFile tmpFile1 else putStrLn "No file Present"
           mainQuit
         onClicked mycancel $ do 
           widgetDestroy bwindow
           --widgetDestroy window
           tmpFile <- readIORef tmpFileName
           val <- doesFileExist tmpFile
           if (val==True) then removeFile tmpFile else putStrLn "No file Present"
           mainQuit
         widgetShowAll bwindow  
         onDestroy bwindow mainQuit
         print "hello"

  
  onActionActivate opna $ do
    openAction fileName tmpFileName tmpFileName1 canvas myFileList
    writeIORef changeList []
----------------------------------------------------------------------------------    
  onActionActivate nexa $ do
    tempfileList <- readIORef myFileList
    putStrLn "NEXT PRESSED"
    fileList <- return (goForward tempfileList)
    writeIORef myFileList fileList
    printFileList fileList
    frontFile <- return $ getFrontFile fileList 
    case frontFile of 
      "" -> 
        putStrLn "End of List"
      _ ->
        do
          putStrLn frontFile 
          basename <- return (takeBaseName frontFile)
          myimg <- loadImgFile frontFile  -- load image from this location 
          ext <- return (takeExtension frontFile)
          saveImgFile (-1) (basename++"temp"++ext) myimg -- save temp file in code ir for future use
          writeIORef tmpFileName (basename++"temp"++ext) -- remember temp file's ame
          writeIORef tmpFileName1 (basename++"temp1"++ext) -- remember temp file's name
          imageSetFromFile canvas (basename++"temp"++ext) -- render the image from temp file on canvas
          putStrLn $ "Opening File: " ++ frontFile
    
    
    
  onActionActivate baca $ do
    tempfileList <- readIORef myFileList
    putStrLn "BACK PRESSED"
    printFileList tempfileList
    fileList <- return (goBackward tempfileList)
    writeIORef myFileList fileList
    printFileList fileList
    frontFile <- return $ getFrontFile fileList 
    case frontFile of 
      "" -> 
        putStrLn "End of List"
      _ ->
        do
          putStrLn frontFile 
          basename <- return (takeBaseName frontFile)
          myimg <- loadImgFile frontFile  -- load image from this location 
          ext <- return (takeExtension frontFile)
          saveImgFile (-1) (basename++"temp"++ext) myimg -- save temp file in code ir for future use
          writeIORef tmpFileName (basename++"temp"++ext) -- remember temp file's ame
          writeIORef tmpFileName1 (basename++"temp1"++ext) -- remember temp file's name
          imageSetFromFile canvas (basename++"temp"++ext) -- render the image from temp file on canvas
          putStrLn $ "Opening File: " ++ frontFile
            
    
--------------------------------------------------------------------------------------------------
  
  onActionActivate unda $ do    -- user pressed undo button
    effectList <- readIORef changeList -- get all the changes that have been made so far
    originalPath <- readIORef fileName -- pick the original image
    tmpPath <- readIORef tmpFileName -- read temp image path for overwriting
    newImg <- undoLast effectList (loadImgFile originalPath) -- function that will apply all but last of the effects present in the list 
    saveImgFile (-1) tmpPath newImg
    imageSetFromFile canvas tmpPath
    case effectList of
      [] -> do
        writeIORef changeList []
      _ -> do
        writeIORef changeList (init effectList)
        
      
  
--------------------------------------------------------------------- 
  onActionActivate zina $ zoomInOut zoomAmount tmpFileName canvas 1
  onActionActivate zoua $ zoomInOut zoomAmount tmpFileName canvas (-1)
---------------------------------------------------------------------
  onActionActivate rraa $ rotateA tmpFileName canvas 1
  onActionActivate rlaa $ rotateA tmpFileName canvas (-1)
---------------------------------------------------------------------    
  onActionActivate sava $ do
    fpath <- readIORef fileName
    tmpFile <- readIORef tmpFileName
    myImg <- loadImgFile tmpFile
    saveImgFile (-1) fpath myImg
      
  {--   
  Effects added : Grayscale,Brightness
  --}
  onClicked button1 $ noArgEffect grayscale changeList tmpFileName canvas -- add edgeDetect,emboss,meanRemoval,negative like this
-----------------------------------------------------------------------------
  onClicked button6 $ noArgEffect duoTone changeList tmpFileName canvas
  onClicked sepiaButton $ noArgEffect sepia changeList tmpFileName canvas    
  onClicked button5 $ noArgEffect gaussianBlur changeList tmpFileName canvas    
  onClicked invertButton $ noArgEffect negative changeList tmpFileName canvas    
  onClicked embossButton $ noArgEffect emboss changeList tmpFileName canvas    
  onClicked meanButton $ noArgEffect meanRemoval changeList tmpFileName canvas    
  onClicked edgeButton $ noArgEffect edgeDetect changeList tmpFileName canvas
  onClicked yEdgeButton $ noArgEffect sobelY changeList tmpFileName canvas    
  onClicked xEdgeButton $ noArgEffect sobelX changeList tmpFileName canvas        
-----------------------------------------------------------------------------
  {-onClicked colorixeButton $ do
    bwindow <- windowNew
    set bwindow [windowTitle := "Color Selection",
				containerBorderWidth := 10 ]
    vb <- vBoxNew False 0
    containerAdd bwindow vb
    colb <- colorButtonNew
    boxPackStart vb colb PackGrow 0
    
    onColorSet colb $ do colour <- colorButtonGetColor colb
                         case colour of 
                           (Color r g b)->rr = fromIntegral r / 255							
                                          rg = fromIntegral g / 255									
                                          rb = fromIntegral b / 255							
                                          ra = fromIntegral 1 / 255
                                          --in rgb=(rr,rg,rb,ra)     
                         putStrLn (show  colour)

    
    
    widgetShowAll bwindow
    onDestroy bwindow mainQuit
    mainGUI
-}
----------------------------------------------------------------------------
  onClicked button2 $ do
    bwindow  <- windowNew
    set bwindow [windowTitle := "Brightness-Contrast",
              windowDefaultHeight := 200,
              windowDefaultWidth := 300]
    mainbox <- vBoxNew False 10
    containerAdd bwindow mainbox
    containerSetBorderWidth mainbox 10
    box1 <- vBoxNew False 0
    boxPackStart mainbox box1 PackNatural 0
    adj1 <- adjustmentNew 0.0 (-100.0) 100.0 1.0 1.0 1.0
    adj2 <- adjustmentNew 0.0 (-100.0) 100.0 1.0 1.0 1.0
    hsc1 <- hScaleNew adj1
    hsc2 <- hScaleNew adj2
  
    hbox1 <- hBoxNew False 0
    containerSetBorderWidth hbox1 10
    label1 <- labelNew (Just "Brightness:")
    boxPackStart hbox1 label1 PackNatural 0
    boxPackStart hbox1 hsc1 PackGrow 0
    hbox2 <- hBoxNew False 0
    containerSetBorderWidth hbox2 10
    label2 <- labelNew (Just "Contrast:")
    boxPackStart hbox2 label2 PackNatural 0
    boxPackStart hbox2 hsc2 PackGrow 0	
    hbox3 <- hBoxNew False 0
    containerSetBorderWidth hbox3 10
    okbutton <-buttonNewWithLabel "OK"
    
    onClicked okbutton $  do
		val1 <- adjustmentGetValue adj1
		val2 <- adjustmentGetValue adj2
		opList <- readIORef changeList 
		writeIORef changeList (opList++[(flip (brightness) (truncate val1))]) -- add f to the list of effects applied so far
		writeIORef changeList (opList++[(flip (contrast)  (truncate val2))]) -- add f to the list of effects applied so far
		okAction tmpFileName tmpFileName1 bwindow
 
    cancelButton <- buttonNewWithLabel "Cancel"
    
    onClicked cancelButton $ cancelAction tmpFileName tmpFileName1 bwindow canvas
    
    boxPackStart hbox3 okbutton PackGrow 0
    boxPackStart hbox3 cancelButton PackGrow 0
    
  
    boxPackStart box1 hbox1 PackNatural 0
    boxPackStart box1 hbox2 PackNatural 0
    boxPackStart box1 hbox3 PackNatural 0
  
    boxPackStart mainbox box1 PackGrow 0
    onValueChanged adj1 $ do 
      tmpFile <- readIORef tmpFileName
      tmpFile1 <- readIORef tmpFileName1
      val <- adjustmentGetValue adj1
      --writeIORef tmpFileName tmpFile
      myimg <- loadImgFile tmpFile -- load image from this location 
      brightness myimg $ truncate val
      saveImgFile (-1) tmpFile1 myimg
      imageSetFromFile canvas tmpFile1
      
        
    onValueChanged adj2 $ do
      tmpFile <- readIORef tmpFileName
      tmpFile1 <- readIORef tmpFileName1
      val <- adjustmentGetValue adj2
      --writeIORef tmpFileName tmpFile
      myimg <- loadImgFile tmpFile -- load image from this location 
      contrast myimg $ truncate val
      saveImgFile (-1) tmpFile1 myimg
      imageSetFromFile canvas tmpFile1
      
    widgetShowAll bwindow
    onDestroy bwindow mainQuit
    mainGUI
  onClicked colorizeButton $ do
--     tmpFile <- readIORef tmpFileName	
--     myimg <- loadImgFile tmpFile                  
--     putStrLn "colorixed press"
     bwindow <- windowNew
     set bwindow [windowTitle := "Colorize the Image", windowDefaultHeight := 100, windowDefaultWidth := 300, containerBorderWidth := 10 ]
     vb <- vBoxNew False 0
     containerAdd bwindow vb
     
     rVal <- newIORef 0
     gVal <- newIORef 0
     bVal <- newIORef 0
     oVal <- newIORef 0
     
     adj1 <- adjustmentNew 0 (-255) 255 1 1 1
     adj2 <- adjustmentNew 0 (-255) 255 1 1 1
     adj3 <- adjustmentNew 0 (-255) 255 1 1 1
     adj4 <- adjustmentNew 0 (-127) 127 1 1 1
     hsc1 <- hScaleNew adj1
     hsc2 <- hScaleNew adj2
     hsc3 <- hScaleNew adj3
     hsc4 <- hScaleNew adj4
     scaleSetDigits hsc1 0
     scaleSetDigits hsc2 0
     scaleSetDigits hsc3 0
     scaleSetDigits hsc4 0
     label1 <- labelNew (Just "Red offset:")
     boxPackStart vb label1 PackNatural 0
     boxPackStart vb hsc1 PackGrow 0
     label2 <- labelNew (Just "Green offset:")
     boxPackStart vb label2 PackNatural 0
     boxPackStart vb hsc2 PackGrow 0
     label3 <- labelNew (Just "Blue offset:")
     boxPackStart vb label3 PackNatural 0
     boxPackStart vb hsc3 PackGrow 0
     label4 <- labelNew (Just "Opacity:")
     boxPackStart vb label4 PackNatural 0
     boxPackStart vb hsc4 PackGrow 0
     sep <- hSeparatorNew
     boxPackStart vb sep PackGrow 10
     hb <- hBoxNew False 0
     boxPackStart vb hb PackGrow 0
     
     myok <- buttonNewWithLabel "OK"
     boxPackStart hb myok PackGrow 0
     
     mycancel <- buttonNewWithLabel "Cancel"
     boxPackStart hb mycancel PackGrow 0
     
     onValueChanged adj1 $ do 
      --putStrLn "Adj1" 
      --myval <- adjustmentGetValue adj1
      --putStrLn ""++myval
      tmpFile <- readIORef tmpFileName
      tmpFile1 <- readIORef tmpFileName1
      val <- adjustmentGetValue adj1
      writeIORef rVal val
      --writeIORef tmpFileName tmpFile
      myimg <- loadImgFile tmpFile -- load image from this location \
      getR <- readIORef rVal
      getG <- readIORef gVal
      getB <- readIORef bVal
      getO <- readIORef oVal
      colorize myimg ((truncate getR), (truncate getG), (truncate getB), (truncate getO))
      saveImgFile (-1) tmpFile1 myimg
      imageSetFromFile canvas tmpFile1
    
     onValueChanged adj2 $ do
      tmpFile <- readIORef tmpFileName
      tmpFile1 <- readIORef tmpFileName1
      val <- adjustmentGetValue adj2
      writeIORef gVal val
      
      --writeIORef tmpFileName tmpFile
      myimg <- loadImgFile tmpFile -- load image from this location \
      getR <- readIORef rVal
      getG <- readIORef gVal
      getB <- readIORef bVal
      getO <- readIORef oVal
      colorize myimg ((truncate getR), (truncate getG), (truncate getB), (truncate getO))
      saveImgFile (-1) tmpFile1 myimg
      imageSetFromFile canvas tmpFile1
     onValueChanged adj3 $ do
      tmpFile <- readIORef tmpFileName
      tmpFile1 <- readIORef tmpFileName1
      val <- adjustmentGetValue adj3
      writeIORef bVal val
      --writeIORef tmpFileName tmpFile
      myimg <- loadImgFile tmpFile -- load image from this location \
      getR <- readIORef rVal
      getG <- readIORef gVal
      getB <- readIORef bVal
      getO <- readIORef oVal
      colorize myimg ((truncate getR), (truncate getG), (truncate getB), (truncate getO))
      saveImgFile (-1) tmpFile1 myimg
      imageSetFromFile canvas tmpFile1
     onValueChanged adj4 $ do
      tmpFile <- readIORef tmpFileName
      tmpFile1 <- readIORef tmpFileName1
      val <- adjustmentGetValue adj4
      writeIORef oVal val
      --writeIORef tmpFileName tmpFile
      myimg <- loadImgFile tmpFile -- load image from this location \
      getR <- readIORef rVal
      getG <- readIORef gVal
      getB <- readIORef bVal
      getO <- readIORef oVal
      colorize myimg ((truncate getR), (truncate getG), (truncate getB), (truncate getO))
      saveImgFile (-1) tmpFile1 myimg
      imageSetFromFile canvas tmpFile1 
      
     onClicked myok $ do
      getR <- readIORef rVal	
      getG <- readIORef gVal
      getB <- readIORef bVal
      getO <- readIORef oVal
     -- colorize myimg ((truncate getR), (truncate getG), (truncate getB), (truncate getO))
      opList <- readIORef changeList
      writeIORef changeList (opList++[(flip (colorize) ((truncate getR), (truncate getG), (truncate getB), (truncate getO)))])
      okAction tmpFileName tmpFileName1 bwindow
   
     onClicked mycancel $ cancelAction tmpFileName tmpFileName1 bwindow canvas
     
     widgetShowAll bwindow
     onDestroy bwindow mainQuit
     mainGUI
----------------------------------------   
  onClicked addText $ do
    tmpFile <- readIORef tmpFileName
    myimgCopy <- loadImgFile tmpFile
    (imWidth, imHeight) <- imageSize myimgCopy
    myWin1 <- windowNew
    set myWin1 [windowTitle := "Add text to Image", windowDefaultWidth := truncate $ 1.2* (fromIntegral imWidth),
     windowDefaultHeight := truncate $ 1.2*(fromIntegral imHeight),
      containerBorderWidth := 10 ]
    vb <- vBoxNew False 0
    containerAdd myWin1 vb
    myCanvas <- imageNewFromFile tmpFile
    eb1 <- eventBoxNew
    boxPackStart vb eb1 PackGrow 0
    set eb1[containerChild := myCanvas]
    miscSetAlignment myCanvas 0 0
    
    sep1 <- hSeparatorNew
    boxPackStart vb sep1 PackGrow 10
    mylab <- labelNew (Just "Click on the image to specify the start point of the text")
    boxPackStart vb mylab PackGrow 0
    sep2 <- hSeparatorNew
    boxPackStart vb sep2 PackGrow 10
    hb <- hBoxNew False 0
    boxPackStart vb hb PackGrow 0
     
    myok1 <- buttonNewWithLabel "OK" 
    boxPackStart hb myok1 PackGrow 0
    mycancel1 <- buttonNewWithLabel "Cancel"
    boxPackStart hb mycancel1 PackGrow 0
    myclose1 <- buttonNewWithLabel "Close"
    boxPackStart hb myclose1 PackGrow 0
    widgetSetSensitivity myok1 False  
    widgetSetSensitivity mycancel1 False
    onButtonPress eb1 (\x -> do  
							p1 <- widgetGetPointer myCanvas
							writeIORef textPoint p1
							myWin2 <- windowNew
							set myWin2 [windowTitle := "Add text to Image", windowDefaultHeight := 100, windowDefaultWidth := 300, containerBorderWidth := 10 ]
							vb <- vBoxNew False 0
							containerAdd myWin2 vb
							qtlab <- entryNew
							boxPackStart vb qtlab PackGrow 0

							sep <- hSeparatorNew
							boxPackStart vb sep PackGrow 10
							fntb <- fontButtonNew
							boxPackStart vb fntb PackGrow 0
							colb <- colorButtonNew
							boxPackStart vb colb PackGrow 0
							sep2 <- hSeparatorNew
							boxPackStart vb sep2 PackGrow 10
							hb <- hBoxNew False 0
							boxPackStart vb hb PackGrow 0
							myok <- buttonNewWithLabel "OK"
							boxPackStart hb myok PackGrow 0
							mycancel <- buttonNewWithLabel "Cancel"
							boxPackStart hb mycancel PackGrow 0
							
							onFontSet fntb $ do 
							  name <- fontButtonGetFontName fntb
							  putStrLn (show name)
							  fdesc <- fontDescriptionFromString name
							  myFamily <- fontDescriptionGetFamily fdesc
							  myWeight <- fontDescriptionGetWeight fdesc
							  mySize <- fontDescriptionGetSize fdesc
							  myStyle <- fontDescriptionGetStyle fdesc
							  fontStr <- getFontFamily myFamily
							  writeIORef fontFamily fontStr
							  sizeStr <- getFontSize mySize
							  writeIORef fontSize sizeStr
							  widgetModifyFont qtlab (Just fdesc)
							onColorSet colb $ do 
							  colour <- colorButtonGetColor colb
							  widgetModifyFg qtlab StateNormal colour
							  putStrLn (show  colour)
							  (r, g, b) <- getMyCol colour
							  writeIORef textColor (r, g, b)
							onClicked myok $ do
							  imFontFamily <- readIORef fontFamily
							  imFontSize <- readIORef fontSize
							  (imR, imG, imB) <- readIORef textColor
							  putStrLn ((show imR) ++ " " ++ (show imG)  ++ " " ++ (show imB))
							  imTxt <- entryGetText qtlab
							  writeIORef textData imTxt
							  putStrLn imTxt
							  putStrLn imFontFamily
							  putStrLn $ show imFontSize
							  myimg <- loadImgFile tmpFile
							  drawString1 ("./fonts/" ++ imFontFamily ++ ".ttf") imFontSize 0 p1 imTxt (rgb imR imG imB) myimg 
							  saveImgFile (-1) tmpFile myimg
							  imageSetFromFile myCanvas tmpFile
							  widgetDestroy myWin2
							  widgetSetSensitivity myok1 True  
							  widgetSetSensitivity mycancel1 True
							  putStrLn "ok in win2"
							onClicked mycancel $ do
							  widgetDestroy myWin2
							  putStrLn "cancel in win2"
							widgetShowAll myWin2
							onDestroy myWin2 mainQuit
							mainGUI
							return (True))					 
    onClicked myclose1 $ do
      saveImgFile (-1) tmpFile myimgCopy
      widgetDestroy myWin1
      putStrLn "close in win1"
    onClicked mycancel1 $ do
      saveImgFile (-1) tmpFile myimgCopy
      imageSetFromFile myCanvas tmpFile
      widgetSetSensitivity myok1 False
      widgetSetSensitivity mycancel1 False
      putStrLn "cancel in win1"
    onClicked myok1 $ do
      opList <- readIORef changeList
      imFontFamily <- readIORef fontFamily
      imFontSize <- readIORef fontSize
      p1 <- readIORef textPoint
      myData <- readIORef textData
      (imR, imG, imB) <- readIORef textColor
      writeIORef changeList (opList++[(drawString1 imFontFamily imFontSize 0 p1 myData (rgb imR imG imB))])
      imageSetFromFile canvas tmpFile
      widgetDestroy myWin1
      putStrLn "ok in win1"
         
    widgetShowAll myWin1
    onDestroy myWin1 mainQuit
    mainGUI
    putStrLn "Hello" 
---------------------------------------------------
  onClicked button3 $ do
    tmpFile <- readIORef tmpFileName
    myimg <- loadImgFile tmpFile
    (imWidth, imHeight) <- imageSize myimg
    myimgCopy <- copyImage myimg
    putStrLn (show imWidth)
    myWin <- windowNew
    set myWin [windowTitle := "Crop", windowDefaultWidth := truncate $ 1.2* (fromIntegral imWidth),
     windowDefaultHeight := truncate $ 1.2*(fromIntegral imHeight),
      containerBorderWidth := 10 ]
    vb <- vBoxNew False 0
    containerAdd myWin vb
    myCanvas <- imageNewFromFile tmpFile
    eb1 <- eventBoxNew
    boxPackStart vb eb1 PackGrow 0
    set eb1[containerChild := myCanvas]
    miscSetAlignment myCanvas 0 0
    
    sep <- hSeparatorNew
    boxPackStart vb sep PackGrow 10
    hb <- hBoxNew False 0
    boxPackStart vb hb PackGrow 0
     
    myok <- buttonNewWithLabel "Crop to Selection"
    boxPackStart hb myok PackGrow 0     
    mycancel <- buttonNewWithLabel "Cancel"
    boxPackStart hb mycancel PackGrow 0
    myclose <- buttonNewWithLabel "Close"
    boxPackStart hb myclose PackGrow 0
    widgetSetSensitivity myok False
    widgetSetSensitivity mycancel False
    --setCursor window Crosshair
    
    --set viewPort[containerChild := eb]
    onButtonPress eb1 (\x -> do  
							p5 <- miscGetAlignment myCanvas
							p1 <- widgetGetPointer myCanvas
							writeIORef upLeft p1
							onButtonRelease eb1 
								(\x -> do
									p2 <- widgetGetPointer myCanvas
									putStrLn ("Up Left: " ++ show p1)
									putStrLn ("Down Right: " ++ show p2)
									writeIORef downRight p2
									tmpFile <- readIORef tmpFileName
									myimg <- loadImgFile tmpFile -- load image from this location 
									cropRect myimg p1 p2
									saveImgFile (-1) tmpFile myimg
									widgetSetSensitivity myok True
									widgetSetSensitivity mycancel True
									--setCursor window Arrow
									imageSetFromFile myCanvas tmpFile
									return True)
							return (True))					 
    --putStrLn "Hello"
    
    onClicked myok $ do
      p1 <- readIORef upLeft
      p2 <- readIORef downRight
      opList <- readIORef changeList
      crop tmpFile p1 p2 myimg
      --saveImgFile (-1) tmpFile myimg
      print (length opList)
      writeIORef changeList (opList++[crop tmpFile p1 p2])
      --newCrop img1 (p1,p2)
      opList <- readIORef changeList
      print (length opList)      
      imageSetFromFile canvas tmpFile
      widgetDestroy myWin
    onClicked mycancel $ do
      saveImgFile (-1) tmpFile myimgCopy
      imageSetFromFile myCanvas tmpFile
      widgetSetSensitivity myok False
      widgetSetSensitivity mycancel False
    onClicked myclose $ do
      saveImgFile (-1) tmpFile myimgCopy
      widgetDestroy myWin  

    widgetShowAll myWin
    onDestroy myWin mainQuit
    mainGUI       
    
  widgetShowAll window  
  onDestroy window $ do 
    effectList <- readIORef changeList
    case effectList of               
      [] -> do
         tmpFile <- readIORef tmpFileName
         val <- doesFileExist tmpFile
         if (val==True) then removeFile tmpFile else putStrLn "No file Present"
         mainQuit
      _ -> do
         bwindow <- windowNew
         set bwindow [windowTitle := "Save the changes?", windowDefaultHeight := 100, windowDefaultWidth := 300, containerBorderWidth := 10 ]
         vb <- vBoxNew False 0
         containerAdd bwindow vb
         hb <- hBoxNew False 0
         boxPackStart vb hb PackGrow 0
         myok <- buttonNewWithLabel "OK"
         boxPackStart hb myok PackGrow 0
         mycancel <- buttonNewWithLabel "Cancel"
         boxPackStart hb mycancel PackGrow 0
         onClicked myok $ do
           putStrLn "HELLLLLLO"
           tmpFile1 <- readIORef tmpFileName
           originalFileName <- readIORef fileName
           img <- loadImgFile tmpFile1
           saveImgFile (-1) originalFileName img
           widgetDestroy bwindow
           val <- doesFileExist tmpFile1
           if (val==True) then removeFile tmpFile1 else putStrLn "No file Present"
           mainQuit
           --widgetDestroy window
         onClicked mycancel $ do 
           widgetDestroy bwindow
           tmpFile <- readIORef tmpFileName
           val <- doesFileExist tmpFile
           if (val==True) then removeFile tmpFile else putStrLn "No file Present"
           --mainQuit
           --widgetDestroy window
           mainQuit
         widgetShowAll bwindow
         print "EMPTY" 
  --tmpFile <- readIORef tmpFileName
  --val <- doesFileExist tmpFile
  --if (val==True) then removeFile tmpFile else putStrLn "No file Present" 
  mainGUI
     
uiDecl=  "<ui>\
\           <menubar>\
\            <menu action=\"FMA\">\
\              <menuitem action=\"OPNA\" />\
\              <menuitem action=\"SAVA\" />\
\              <separator />\
\              <menuitem action=\"EXIA\" />\
\            </menu>\
\           <menu action=\"EMA\">\
\              <menuitem action=\"UNDA\" />\
\              <menuitem action=\"ZINA\" />\
\              <menuitem action=\"ZOUA\" />\
\              <menuitem action=\"NEXA\" />\
\              <menuitem action=\"BACA\" />\
\           </menu>\
\            <separator />\
\            <menu action=\"HMA\">\
\              <menuitem action=\"HLPA\" />\
\            </menu>\
\           </menubar>\
\           <toolbar>\
\            <toolitem action=\"OPNA\" />\
\            <toolitem action=\"SAVA\" />\
\            <toolitem action=\"EXIA\" />\
\            <separator />\
\            <toolitem action=\"UNDA\" />\
\            <toolitem action=\"ZINA\" />\
\            <toolitem action=\"ZOUA\" />\
\            <toolitem action=\"RRAA\" />\
\            <toolitem action=\"RLAA\" />\
\            <toolitem action=\"NEXA\" />\
\            <toolitem action=\"BACA\" />\
\            <separator />\
\            <toolitem action=\"HLPA\" />\
\           </toolbar>\
\          </ui>"

