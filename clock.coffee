clock = 
  
  config:
    age:          25
    expectancy:   85
    reverse:      false
    labels:       true
    percentage:   true
    hue:          195
    label_color:  90
  
  radii: []
  
  styles: {}

  initialize:->
    @canvas = $("#clock")[0]
    @ctx = @canvas.getContext("2d")
    @line_width = 50
    @setRadii()
    @setTime()
    $("#options").delegate "select", "change click keyup blur", ()->
      option = $(this).val().toLowerCase()
      clock.config[option.replace(' ', '').replace(/hide|show/, '').replace('normal', 'reverse')] = !option.match(/hide|normal/)
      if option.match(/reverse|normal/)
        clock.setRadii()
    $("#sliders").delegate "input", "change click keyup blur", ()->
      clock.config[$(this)[0].className] = Math.max(Math.min($(this).val(), $(this).attr("max")), $(this).attr("min"))
      clock.setRadii()

  setRadii:->
    for item in ["minute", "hour", "day", "week", "year", "decade", "life"] 
      if clock.config["reverse"] is true
        clock.radii[item] = (@line_width * _i) + (@line_width)
      else
        clock.radii[item] = _len * @line_width - @line_width * _i
      @styles[item] = "hsl(#{clock.config.hue}, 100%, #{60 - (_i/(_len*2))*100}%)"
        
  draw:(end, type)->
    radius = @radii[type]
    @ctx.beginPath()
    @ctx.lineWidth = @line_width + 2
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
    @ctx.fonm
    offset = 5
    for item of @radii
      percent = parseInt((@styles[item].split(' ')[@styles[item].split(' ').length-1]).split(')')[0])
      @ctx.fillStyle = "hsl(0, 0%, #{clock.config.label_color}%)"
      text = ""
      text = item if @config.labels
      text += " - " if @config.labels and @config.percentage
      text += "#{parseInt(clock[item]/60*100)}%" if @config.percentage
      @ctx.fillText(text, @canvas.width/2+offset, @canvas.height/2-@radii[item]+offset) if text


  drawClock:->  
    @ctx.fillStyle = "black"
    @ctx.fillRect(0,0,@canvas.width, @canvas.height)
    @draw(@minute, "minute") 
    @draw(@hour, "hour") 
    @draw(@day, "day") 
    @draw(@week, "week") 
    @draw(@year, "year") 
    @draw(@decade, "decade") 
    @draw(@life, "life") 
    @drawText()
    @minute = 0 if @minute >= 60
    window.setTimeout('clock.setTime()', 10)

  setTime:->
    d = (new Date())
    @minute = d.getSeconds() + (parseInt(d.getTime() / 10) % parseInt(d.getTime() / 1000)) / 100
    @hour = d.getMinutes() + (@minute/60)
    @day = d.getHours() + (@hour/60)
    @week = (d.getDay() / 7) * 60
    c = new Date(d.getFullYear(), 0, 1) # http://javascript.about.com/library/bldayyear.htm
    @year = (Math.ceil((d - c) / 86400000)) / 365 * 60 # http://javascript.about.com/library/bldayyear.htm
    @decade = (d.getYear() % 10) / 10  * 60
    @life = (clock.config.age / clock.config.expectancy) * 60
    @drawClock()
    