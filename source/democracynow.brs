
Sub Main()
    theme = CreateObject("roAssociativeArray")
    theme.OverhangOffsetSD_X = "35"
    theme.OverhangOffsetSD_Y = "15"
    theme.OverhangSliceSD = "pkg:/images/Overhang_Background_SD.png"
    theme.OverhangLogoSD  = "pkg:/images/Overhang_Logo_SD.png"
    theme.OverhangOffsetHD_X = "40"
    theme.OverhangOffsetHD_Y = "20"
    theme.OverhangSliceHD = "pkg:/images/Overhang_Background_HD.png"
    theme.OverhangLogoHD  = "pkg:/images/Overhang_Logo_HD.png"
	theme.BreadcrumbTextRight = "#606060"
    app = CreateObject("roAppManager")
    app.SetTheme(theme)
	ShowShows()
End Sub

Sub ShowShows()
    port = CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetListStyle("flat-category")
    screen.SetMessagePort(port)
    records = LoadShows()
    screen.SetContentList(records)
	screen.SetBreadcrumbText("", "DemocracyNow.org")
    screen.Show()

    while true
        msg = wait(0, port)
        if type(msg) = "roPosterScreenEvent" then
            if msg.isScreenClosed() then
                return
            else if msg.isListItemSelected() then
              ShowEpisodeDetail(records[msg.GetIndex()])
            endif
        endif
    end while
End Sub

Function LoadShows() As Object
    http = NewHttp("http://www.democracynow.org/podcast-video.xml")
    rsp = http.GetToStringWithRetry()
    xml = CreateObject("roXMLElement")
    xml.Parse(rsp)
    records = xml.GetChildElements()
    results = CreateObject("roArray", 0, true)
    
    for each rec in records.item
	    if type(rec.enclosure@url)<>"Invalid" then
          item = CreateObject("roAssociativeArray")
		  print rec.title.getText()
          item.Title = rec.title.getText()
          item.ShortDescriptionLine1 = rec.title.getText()
          item.Description = Left(rec.description.getText(), 197) + "..."
          item.Type = "series"
		  print rec.GetNamedElements("media:thumbnail")@url
          item.SDPosterURL = rec.GetNamedElements("media:thumbnail")@url
          item.HDPosterURL = rec.GetNamedElements("media:thumbnail")@url
          item.StreamUrls = rec.enclosure@url
		  durat = rec.GetNamedElements("media:content")@duration
		  item.Length = durat.ToInt() 
		  item.Categories = rec.GetNamedElements("media:content")[0].GetNamedElements("media:category")[0].GetText()
		  item.Actors = records.GetNamedElements("itunes:author")[0].GetText()
          results.Push(item)
		endif
    next
    return results
End Function



Sub ShowEpisodeDetail(arec As Object)

    port = CreateObject("roMessagePort")
    screen = CreateObject("roSpringboardScreen")
    screen.SetMessagePort(port)
    screen.SetStaticRatingEnabled(False)
	screen.SetBreadcrumbText("", "DemocracyNow.org")
	
    ids = CreateObject("roArray", 0, true)
    ids.Push(arec.StreamUrls)
    
    quals = CreateObject("roArray", 0, true)
    quals.Push(0)

    rates = CreateObject("roArray", 0, true)
    rates.Push(0)
    
    record = arec
    record.ContentType = "episode"
    record.StreamQualities = quals
    record.StreamBitrates = rates
    record.StreamFormat = "mp4"
    record.IsHD = false
    record.StreamContentIDs = ids
    
    screen.SetContent(arec)
    screen.AddButton(1, "play from beginning")

    resume = RegRead(record.StreamUrls)
    start = 0

    if resume <> invalid then
        screen.AddButton(2, "resume")
        start = resume.ToInt()
    end if

    screen.SetContent(record)
    screen.Show()

    while true
        msg = wait(0, port)
        if type(msg) = "roSpringboardScreenEvent" then
            if msg.isScreenClosed() then
                exit while
            else if msg.isButtonPressed() then
                button = msg.GetIndex()
                if button = 1 then
                   start = 0
                endif
                PlayEpisode(record, start)
            endif
        endif
    end while
End Sub

Sub PlayEpisode(arec As Object, start As Integer)

    port = CreateObject("roMessagePort")
    screen = CreateObject("roVideoScreen")
    screen.SetMessagePort(port)
    screen.SetPositionNotificationPeriod(30)	
    record = arec
    record.PlayStart = start
    screen.SetContent(arec)
    screen.Show()

    while true
        msg = wait(0, port)
        if type(msg) = "roVideoScreenEvent" then
            if msg.isScreenClosed() then
                exit while
            else if msg.isPlaybackPosition() then
                RegWrite(arec.StreamUrls, msg.GetIndex().toStr())
            endif
        endif
    end while
End Sub
