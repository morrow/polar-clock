clock = 

  contexts: ["minute", "hour", "day", "week", "month", "year", "decade", "life"] 
  
  config:
    age:          25
    gender:       "male"
    bmi:          25
    expectancy:   75
    hue:          195
    lightlabels:  true
    smoker:       false
    reverse:      false
    labels:       true
    percentage:   true
    grid:         true
    line_width:   50
  
  radii: []
  
  styles: {}

  initialize:->
    @canvas = $("#clock")[0]
    @ctx = @canvas.getContext("2d")
    @loadConfig()
    @setRadii()
    @calculateExpectancy()
    $(".options").live("mouseover", ()-> $(".options").addClass("hovered"))
    $("#clock").live("mouseover", ()-> $(".options").removeClass("hovered"))
    $("#clock-options select").live "change click keyup blur", ->
      option = $(this).val().toLowerCase()
      clock.config[option.replace(' ', '').replace(/hide|show/, '').replace('normal', 'reverse').replace('dark','light')] = !option.match(/hide|normal|dark/)
      clock.setRadii() if option.match(/reverse|normal/)
    $("[input[type=range]").live "change click keyup blur", ->
      clock.config[$(this)[0].className] = Math.max(Math.min($(this).val(), $(this).attr("max")), $(this).attr("min"))
      clock.setRadii()
      clock.saveConfig()
    $("#personal-options").delegate "input, select", "change click keyup blur", ->
      console.log $(this)[0].className
      console.log $(this).val().toLowerCase()
      value = $(this).val().toLowerCase()
      if $(this)[0].className.match /gender|bmi|age/
        clock.config[$(this)[0].className] = value
      else if $(this)[0].className.match /smoker/
        clock.config["smoker"] = !value.match(/non-smoker/)
      clock.calculateExpectancy()
      clock.saveConfig()
    window.setInterval('clock.setTime("all")', 1000)
    window.setInterval('clock.setTime("minute")', 50)

  calculateExpectancy:->
    # http://www.ncbi.nlm.nih.gov/pmc/articles/PMC2662372/?tool=pmcentrez
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
    console.log expectancy
    $(".expectancy.output").text(clock.config.expectancy = Math.round(expectancy))

  loadConfig:->
    try
      config = JSON.parse window.localStorage["config"] if window.localStorage["config"] 
    catch error
      config = false
    clock.config = config if typeof config is "object"
    for item of clock.config
      if $(".#{item}").length
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


  drawText:->
    @ctx.font = "bold 13px arial"
    offset = 5
    for item of @radii
      percent = parseInt((@styles[item].split(' ')[@styles[item].split(' ').length-1]).split(')')[0])
      if clock.config.lightlabels
        @ctx.fillStyle = "white"
      else
        @ctx.fillStyle = "black"
      text = ""
      text = item if @config.labels
      text += " - " if @config.labels and @config.percentage
      text += "#{Math.round(clock[item]/60*100)}%" if @config.percentage
      @ctx.fillText(text, @canvas.width/2+offset, @canvas.height/2-@radii[item]+offset) if text

  drawGrid:->
    return false if not @config.grid
    @ctx.beginPath()
    @ctx.lineWidth = 1
    @ctx.strokeStyle = "rgba(0,0,0,.4)"
    @ctx.moveTo(@canvas.width/2, 0)
    @ctx.lineTo(@canvas.width/2, @canvas.height)
    @ctx.moveTo(0, @canvas.height/2)
    @ctx.lineTo(@canvas.width, @canvas.height/2)
    @ctx.stroke()
    @ctx.closePath()

  drawClock:(context="all")->  
    @ctx.fillStyle = "black"
    @ctx.fillRect(0,0,@canvas.width, @canvas.height)
    for item in @contexts
      if context is item or "all"
        @draw(clock[item], item)
    @drawText(context)
    @drawGrid()
    @minute = 0 if @minute >= 60

  setTime:(context="all")->
    d = (new Date())
    d2 = new Date(d.getFullYear(), 0, 1)
    if context is "minute" or "all"
      @minute = d.getSeconds() + (parseInt(d.getTime() / 10) % parseInt(d.getTime() / 1000)) / 100
    if context is "hour" or "all"
      @hour = d.getMinutes() + (@minute / 60)
    if context is "day" or "all"
      @day = (d.getHours() + (@hour / 60)) / 24 * 60
    if context is "week" or "all"
      @week = ((d.getDay() + d.getHours() / 24) / 7) * 60
    if context is "month" or "all"
      @month = (d.getDate() / (32 - new Date(d.getYear(), d.getMonth(), 32).getDate())) * 60 + @day/60
    if context is "year" or "all"
      @year = (Math.ceil((d - d2) / 86400000) + @day / 60) / 365 * 60
    if context is "decade" or "all"
      @decade = (d.getYear() % 10  + ((Math.ceil((d - d2) / 86400000)) / 365) + @hour / 60 / 365) / 10  * 60
    if context is "life" or "all"
      @life = ((clock.config.age*365*24 + (Math.ceil((d - d2) / 86400000)) + @hour / 60)  / (clock.config.expectancy*365*24)) * 60
      $(".age").val(@config.age=1) if @life == 60
    @drawClock(context)