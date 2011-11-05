clock = 

  config:
    age:              25
    gender:           "male"
    bmi:              25
    expectancy:       75
    hue:              195
    lightlabels:      true
    smoker:           false
    reverse:          false
    rotate:           false
    rotate_context:   "minute"
    show_labels:      true
    show_percentage:  false
    show_grid:        true
    line_width:       50

  #contexts: ["minute", "hour", "day", "week", "month", "year", "decade", "life", "century", "millenium", "earth"] #arbitrary times included
  contexts: ["second", "minute", "hour", "day", "week", "month", "year", "life", "earth"]
  
  radii: []
  
  styles: {}

  initialize:->
    @canvas = $("#clock")[0]
    @ctx = @canvas.getContext("2d")
    $("#options-toggle").live "click", (e)->
      $("#options").toggle()
    $("body").live "click", (e)->
      if e.target.nodeName.toLowerCase().match /canvas|button/
        $("#options").hide()
    @loadConfig()
    @setRadii()
    @calculateExpectancy()
    $("#clock-options").delegate "input, select", "change click keyup blur", ->
      if $(this).attr("type") is "range"
        clock.config[$(this)[0].className] = Math.max(Math.min($(this).val(), $(this).attr("max")), $(this).attr("min"))
      else if $(this).attr("type") is "checkbox"
        clock.config[$(this)[0].className] = $(this).attr("checked") is "checked"
      else if $(this)[0].nodeName.toLowerCase() is "select"
        clock.config[$(this)[0].className] = $(this).val()
      clock.setRadii()
      clock.saveConfig()
    $("#personal-options").delegate "input, select", "change click keyup blur", ->
      value = $(this).val().toLowerCase()
      if $(this)[0].className.match /gender|bmi|age/
        clock.config[$(this)[0].className] = value
      else if $(this)[0].className.match /smoker/
        clock.config["smoker"] = !!$(this).attr("checked")
      else if $(this)[0].className.match /birthday/
        if $(".birthday").val()
          clock.config.birthday = $(".birthday").val()
      clock.calculateExpectancy()
      clock.saveConfig()
    window.setInterval('clock.setTime("all")', 1000)
    window.setInterval('clock.setTime("minute")', 50)

  calculateExpectancy:->
    # http://www.ncbi.nlm.nih.gov/pmc/articles/PMC2662372/?tool=pmcentrez
    if $(".birthday").val()
      current = new Date()
      birthday = new Date(clock.config.birthday)
      clock.config.age = (current.getTime() - birthday.getTime()) / 86400000 / 365
    age = clock.config.age
    bmi = clock.config.bmi
    gender = clock.config.gender
    smoker = clock.config.smoker
    expectancy = {"male":75,"female":80}[gender]
    if bmi <= 20
      expectancy -= 3
    if bmi > 25
      expectancy -= Math.min(bmi - 25, (bmi-25)/2)
    if smoker
      expectancy -= 10
    $(".expectancy.output").text(clock.config.expectancy = parseInt(expectancy))
    $(".age.output").text(parseInt(clock.config.age * 100)/100)

  loadConfig:->
    try
      config = JSON.parse window.localStorage["config"] if window.localStorage["config"] 
    catch error
      config = false
    if typeof config is "object"
      clock.config = config 
      $("#options").hide()
    for item of clock.config
      if $(".#{item}").length
        if $(".#{item}").attr("type") is "checkbox"
          $(".#{item}")[0].checked = !!clock.config[item]
        else
          $(".#{item}").val(clock.config[item])

  saveConfig:->
    window.localStorage["config"] = JSON.stringify clock.config
    
  setRadii:->
    for item in @contexts
      if clock.config["reverse"] is true
        clock.radii[item] = (@config.line_width * _i) + (@config.line_width)
      else
        clock.radii[item] = _len * @config.line_width - @config.line_width * _i
      @styles[item] = "hsl(#{clock.config.hue}, 100%, #{60 - (_i/(_len*2))*100}%)"
        
  draw:(end, type)->
    radius = @radii[type]
    @ctx.beginPath()
    @ctx.lineWidth = @config.line_width + 2
    @ctx.strokeStyle = @styles[type]
    start = Math.PI * 1.5
    end -= 15
    end = 44.99999 if end == 45
    end /= 60
    end *= (Math.PI*2)
    @ctx.arc(@canvas.width/2, @canvas.height/2, radius, end, start, true)
    @ctx.stroke()
    @ctx.closePath()


  drawText:(context="all")->
    @ctx.font = "bold 13px arial"
    offset = 5
    for item of @radii
      percent = parseInt((@styles[item].split(' ')[@styles[item].split(' ').length-1]).split(')')[0])
      if clock.config.lightlabels
        @ctx.fillStyle = "white"
      else
        @ctx.fillStyle = "black"
      text = ""
      text = item if @config.show_labels
      text += " - " if @config.show_labels and @config.show_percentage
      text += "#{parseInt(clock[item]/60*100)}%" if @config.show_percentage
      @ctx.fillText(text, @canvas.width/2+offset, @canvas.height/2-@radii[item]+offset) if text

  drawGrid:->
    @ctx.beginPath()
    @ctx.lineWidth = 1
    @ctx.strokeStyle = "rgba(0,0,0,.5)"
    if @config.show_grid
      @ctx.moveTo(@canvas.width/2, 0)
      @ctx.lineTo(@canvas.width/2, @canvas.height)
      @ctx.moveTo(0, @canvas.height/2)
      @ctx.lineTo(@canvas.width, @canvas.height/2)
    else
      @ctx.moveTo(@canvas.width/2, 0)
      @ctx.lineTo(@canvas.width/2, @canvas.height/2)
    @ctx.stroke()
    @ctx.closePath()

  rotateClock:(context="all")->
    if not @config.rotate
      $("body").removeClass "rotating"
      $("#clock").css
        "-webkit-transform":"rotate(0deg)"
        "-moz-transform":"rotate(0deg)"
      return false
    rotate = -(clock[@config.rotate_context]*6)
    $("body").addClass "rotating"
    $("#clock").css
      "-webkit-transform":"rotate(#{rotate}deg)"
      "-moz-transform":"rotate(#{rotate}deg)"

  drawClock:(context="all")-> 
    @ctx.fillStyle = "black"
    @ctx.fillRect(0, 0, @canvas.width, @canvas.height)
    for item in @contexts
      if item is context or "all"
        @draw(clock[item], item)
    @minute = 0 if @minute > 60
    @drawGrid(context)
    @drawText(context)
    @rotateClock(context)

  setTime:(context="all")->
    d = (new Date())
    d2 = new Date(d.getFullYear(), 0, 1)
    if context is "second" or "all"
      @second = ((new Date()).getMilliseconds() / 1000) * 60
    if context is "minute" or "all"
      @minute = d.getSeconds() + (parseInt(d.getTime() / 10) % parseInt(d.getTime() / 1000)) / 100
    if context is "hour" or "all"
      @hour = d.getMinutes() + (@minute / 60)
    if context is "day" or "all"
      @day = (d.getHours() + (@hour / 60)) / 24 * 60
    if context is "week" or "all"
      @week = ((d.getDay() - d.getHours() / 24) / 7) * 60
    if context is "month" or "all"
      @month = (d.getDate() / (32 - new Date(d.getYear(), d.getMonth(), 32).getDate())) * 60 - (1 - @day/60)
    if context is "year" or "all"
      @year = (Math.ceil((d - d2) / 86400000) + @day / 60) / 365 * 60
    if context is "decade" or "all"
      @decade = (d.getYear() % 10  + ((Math.ceil((d - d2) / 86400000)) / 365) + @hour / 60 / 365) / 10  * 60
    if context is "life" or "all"
      @life = ((clock.config.age*365*24 + (Math.ceil((d - d2) / 86400000)) + @hour / 60)  / (clock.config.expectancy*365*24)) * 60
      $(".age").val(@config.age=1) if @life == 60
    if context is "century" or "all"
      @century = (((new Date()).getFullYear() % 100) / 100) * 60
    if context is "millenium" or "all"
      @millenium = (((new Date()).getFullYear() % 1000) / 1000) * 60
    if context is "earth" or "all"
      @earth = ((4570000000 + (new Date()).getTime() / 30000000000) / 10000000000) * 60
    @drawClock(context)
